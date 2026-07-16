#!/usr/bin/env bash
# Dumps cluster state for debugging integration-test failures.
#
# Integration tests fail intermittently with "query-test ... returned no results",
# meaning the telemetry pipeline had not shipped data before the query window closed.
# The test tooling only surfaces the query-test pod logs, which look identical for
# every root cause. This script captures the state needed to tell them apart:
# unscheduled/ImagePull Alloy pods, Alloy remote_write errors, a not-ready
# destination, ArgoCD sync lag, or node resource pressure.
#
# Run against a live cluster (KUBECONFIG must point at it) BEFORE it is deleted.
#
# Secrets: this runs in CI whose logs are retained (and public for this repo).
# Test plans embed credentials, so this script (a) never dumps objects that carry
# secret material -- no `get secrets`, no `-o yaml`/`-o json` of specs/values, only
# status fields -- and (b) pipes every command through redact() as defense in depth.

usage() {
  echo "USAGE: collect-integration-test-diagnostics.sh"
  echo ""
  echo "Dumps Kubernetes cluster state for the cluster referenced by KUBECONFIG."
  echo "Intended to run on integration-test failure, before the cluster is deleted."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v kubectl > /dev/null 2>&1; then
  echo "kubectl not found; cannot collect diagnostics."
  exit 0
fi

# redact : mask credential-bearing "key: value" / "key=value" pairs and URL userinfo.
# A backstop only -- the commands below are already chosen to avoid printing secrets.
redact() {
  local keys='(password|passwd|pwd|pass|token|secret|api[_-]?key|apikey|access[_-]?key|client[_-]?secret|credential|bearer)'
  sed -E \
    -e "s#(//[^:/@[:space:]]+):[^@/[:space:]]+@#\1:[REDACTED]@#g" \
    -e "s#(${keys}[\"']?[[:space:]]*[:=][[:space:]]*)([\"'])[^\"']*\3#\1\3[REDACTED]\3#gI" \
    -e "s#(${keys}[\"']?[[:space:]]*[:=][[:space:]]*)[^[:space:],;\"']+#\1[REDACTED]#gI"
}

# run <group title> <command...> : print a collapsible section, redact, never fail.
run() {
  local title="${1}"
  shift
  echo "::group::${title}"
  echo "\$ $*"
  { "$@" 2>&1 || echo "(command exited ${?})"; } | redact
  echo "::endgroup::"
}

echo "### Integration test diagnostics"

# Node capacity and conditions -- surfaces CPU/memory pressure and FailedScheduling.
run "Nodes (wide)" kubectl get nodes -o wide
run "Node describe (allocated resources, conditions)" kubectl describe nodes
run "Node resource usage (needs metrics-server)" kubectl top nodes

# Everything, everywhere -- the fastest read on what is Pending/CrashLooping/ImagePull.
# -o wide (not yaml) so pod env/secret material is never printed.
run "All pods (wide)" kubectl get pods --all-namespaces -o wide
run "Recent events (all namespaces)" \
  kubectl get events --all-namespaces --sort-by=.lastTimestamp

# Flux + Argo delivery state -- is the subject even deployed yet? Status only; the
# specs carry credentials (Argo valuesObject, Flux values) so they are never dumped.
run "Flux HelmReleases" kubectl get helmreleases.helm.toolkit.fluxcd.io --all-namespaces -o wide

if kubectl get crd applications.argoproj.io > /dev/null 2>&1; then
  run "ArgoCD Applications (status)" \
    kubectl get applications.argoproj.io --all-namespaces \
    -o 'custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,OP-PHASE:.status.operationState.phase,MESSAGE:.status.operationState.message'
  run "ArgoCD Application conditions" \
    kubectl get applications.argoproj.io --all-namespaces \
    -o 'jsonpath={range .items[*]}{.metadata.namespace}/{.metadata.name}:{"\n"}{range .status.conditions[*]}  {.type}: {.message}{"\n"}{end}{end}'
fi

# Alloy is the collector: its readiness and logs distinguish "not scheduled" /
# "image pull" / "remote_write failing" / "waiting on a not-ready destination".
alloyPods=$(kubectl get pods --all-namespaces \
  -l app.kubernetes.io/name=alloy \
  -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' 2>/dev/null)

if [[ -z "${alloyPods}" ]]; then
  # Fall back to matching by name for charts that do not set the expected label.
  alloyPods=$(kubectl get pods --all-namespaces \
    -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' 2>/dev/null \
    | grep -i alloy || true)
fi

if [[ -z "${alloyPods}" ]]; then
  echo "::group::Alloy pods"
  echo "No Alloy pods found -- collector was never created (check Flux/ArgoCD state above)."
  echo "::endgroup::"
else
  while IFS='/' read -r ns pod; do
    [[ -z "${ns}" || -z "${pod}" ]] && continue
    # describe can print literal env values; redact() in run() masks credential-like ones.
    run "Alloy describe: ${ns}/${pod}" kubectl describe pod -n "${ns}" "${pod}"
    run "Alloy logs: ${ns}/${pod}" \
      kubectl logs -n "${ns}" "${pod}" --all-containers --tail=200 --prefix
  done <<< "${alloyPods}"
fi

echo "### End of diagnostics"
