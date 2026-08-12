#!/usr/bin/env bash
# Usage: derive-expected.sh <cluster-name> <output-file> [namespace]
set -euo pipefail

CLUSTER="${1:?usage: derive-expected.sh <cluster-name> <output-file> [namespace]}"
OUT="${2:?output file required}"
NAMESPACE="${3:-toolbox}"
SOURCE="${EXPECTED_SOURCE:-k8s-monitoring}"

pipelines="$(gcx fleet pipelines list -o json --limit 0)"

# $1 = jq condition selecting the collector-role bucket.
contents_for() {
  jq -r --arg cluster "${CLUSTER}" --arg source "${SOURCE}" "
    .[]
    | .spec
    | select(any(.matchers[]; . == (\"source=\" + \$source)))
    | select((.metadata.instrumentation.cluster_name == \$cluster) or (.metadata.type == \"discovery\"))
    | select($1)
    | .contents // \"\"
  " <<<"${pipelines}"
}

# Alloy component types are dotted (namespace.name); config sub-blocks and
# declare/argument/export are not. Match a dotted type + quoted label at any indent.
# `|| true`: an empty bucket yields no grep hits (the incident case) and must not abort.
extract() {
  grep -oE '^[[:space:]]*[a-z][a-z0-9]*(\.[a-z0-9_]+)+[[:space:]]+"' \
    | sed -E 's/^[[:space:]]*([a-z0-9._]+)[[:space:]]+"$/\1/' \
    | sort -u || true
}

daemonset="$(contents_for '(any(.matchers[]; . == "workloadType=deployment") | not)' | extract | paste -sd' ' -)"
deployment="$(contents_for 'any(.matchers[]; . == "workloadType=deployment")' | extract | paste -sd' ' -)"

kubectl create configmap expected-components \
  --namespace "${NAMESPACE}" \
  --from-literal=EXPECTED_DAEMONSET="${daemonset}" \
  --from-literal=EXPECTED_DEPLOYMENT="${deployment}" \
  --dry-run=client -o yaml >"${OUT}"

{
  echo "Derived expected components for cluster=${CLUSTER} (source=${SOURCE}):"
  echo "  daemonset:  ${daemonset:-<none>}"
  echo "  deployment: ${deployment:-<none>}"
} >&2
