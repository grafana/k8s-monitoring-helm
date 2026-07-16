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

# run <group title> <command...> : print a collapsible section and never fail the script.
run() {
  local title="${1}"
  shift
  echo "::group::${title}"
  echo "\$ $*"
  "$@" 2>&1 || echo "(command exited ${?})"
  echo "::endgroup::"
}

echo "### Integration test diagnostics"

# Node capacity and conditions — surfaces CPU/memory pressure and FailedScheduling.
run "Nodes (wide)" kubectl get nodes -o wide
run "Node describe (allocated resources, conditions)" kubectl describe nodes
run "Node resource usage (needs metrics-server)" kubectl top nodes

# Everything, everywhere — the fastest read on what is Pending/CrashLooping/ImagePull.
run "All pods (wide)" kubectl get pods --all-namespaces -o wide
run "Recent events (all namespaces)" \
  kubectl get events --all-namespaces --sort-by=.lastTimestamp

# Flux + Argo delivery state — is the subject even deployed yet?
run "Flux HelmReleases" kubectl get helmreleases.helm.toolkit.fluxcd.io --all-namespaces -o wide

if kubectl get crd applications.argoproj.io > /dev/null 2>&1; then
  run "ArgoCD Applications" kubectl get applications.argoproj.io --all-namespaces -o wide
  run "ArgoCD Application details" \
    kubectl get applications.argoproj.io --all-namespaces -o yaml
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
  echo "No Alloy pods found — collector was never created (check Flux/ArgoCD state above)."
  echo "::endgroup::"
else
  while IFS='/' read -r ns pod; do
    [[ -z "${ns}" || -z "${pod}" ]] && continue
    run "Alloy describe: ${ns}/${pod}" kubectl describe pod -n "${ns}" "${pod}"
    run "Alloy logs: ${ns}/${pod}" \
      kubectl logs -n "${ns}" "${pod}" --all-containers --tail=200 --prefix
  done <<< "${alloyPods}"
fi

echo "### End of diagnostics"
