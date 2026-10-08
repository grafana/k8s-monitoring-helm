#!/usr/bin/env bash
# Usage: derive-expected.sh <cluster-name> <output-file> [namespace]
set -euo pipefail

CLUSTER="${1:?usage: derive-expected.sh <cluster-name> <output-file> [namespace]}"
OUT="${2:?output file required}"
NAMESPACE="${3:-toolbox}"
SOURCE="${EXPECTED_SOURCE:-k8s-monitoring}"

pipelines="$(gcx fleet pipelines list -o json --limit 0)"

# The remotecfg attributes a collector advertises to FM, read from its rendered config.
collector_attributes() {
  awk '/attributes = \{/ { a = 1; next } a && /\}/ { exit } a' "$1" \
    | jq -Rn '[inputs | capture("\"(?<key>[^\"]+)\" = \"(?<value>[^\"]*)\"") | {(.key): .value}] | add'
}

# The pipelines FM would deliver to a collector with the given attributes. cluster is
# covered by the cluster_name selection; sourceVersion is ignored so a version
# mismatch surfaces as expected components missing from the running collector.
contents_for() {
  jq -r --arg cluster "${CLUSTER}" --arg source "${SOURCE}" --argjson attrs "$1" '
    def matches:
      capture("^(?<key>[^=~]+)(?<op>=~?)\"?(?<value>.*?)\"?$") as $m
      | ($attrs[$m.key] // "") as $actual
      | if $m.key == "cluster" or $m.key == "sourceVersion" then true
        elif $m.op == "=" then $actual == $m.value
        else $actual | test("^(?:" + $m.value + ")$")
        end;
    .[]
    | .spec
    | select(any(.matchers[]; . == ("source=" + $source)))
    | select((.metadata.instrumentation.cluster_name == $cluster) or (.metadata.type == "discovery"))
    | select(all(.matchers[]; matches))
    | .contents // ""
  ' <<<"${pipelines}"
}

# Alloy component types are dotted (namespace.name); config sub-blocks and
# declare/argument/export are not. Match a dotted type + quoted label at any indent.
# `|| true`: an empty bucket yields no grep hits (the incident case) and must not abort.
extract() {
  grep -oE '^[[:space:]]*[a-z][a-z0-9]*(\.[a-z0-9_]+)+[[:space:]]+"' \
    | sed -E 's/^[[:space:]]*([a-z0-9._]+)[[:space:]]+"$/\1/' \
    | sort -u || true
}

# Components FM would deliver to this tier's collector of the given workloadType
# (empty when the tier has no such collector).
expected_components() {
  local rendered attrs
  for rendered in .rendered/*.alloy; do
    attrs="$(collector_attributes "${rendered}")"
    if [ "$(jq -r '.workloadType' <<<"${attrs}")" = "$1" ]; then
      contents_for "${attrs}" | extract | paste -sd' ' -
    fi
  done
}

daemonset="$(expected_components daemonset)"
deployment="$(expected_components deployment)"

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
