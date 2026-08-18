#!/usr/bin/env bash
# Usage: provision.sh <cluster-name>
set -euo pipefail

CLUSTER="${1:?usage: provision.sh <cluster-name>}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

echo "Provisioning Instrumentation Hub (SetupK8sDiscovery + SetK8SInstrumentation) for cluster=${CLUSTER}..." >&2

gcx instrumentation setup "${CLUSTER}" --use-defaults --node-logs --energy-metrics >/dev/null

# Family 3 (application observability / otel-receiver): the deployment-collector
# assertion (standard/maximum) needs FM to hold a workloadType=deployment pipeline.
# Only those tiers set IHUB_APP_NAMESPACE; minimal (daemonset-only) leaves it unset
# and skips this. Uses curl, not gcx — see set-app-observability.sh for why.
if [ -n "${IHUB_APP_NAMESPACE:-}" ]; then
  echo "Enabling application observability (otel-receiver) for namespace=${IHUB_APP_NAMESPACE}..." >&2
  "${SCRIPTS}/set-app-observability.sh" "${CLUSTER}" "${IHUB_APP_NAMESPACE}" true
fi

echo "Provisioned. FM pipelines now held for cluster=${CLUSTER}:" >&2
gcx fleet pipelines list -o json --limit 0 \
  | jq -r --arg c "${CLUSTER}" '.[]
      | select((.spec.metadata.instrumentation.cluster_name == $c) or (.spec.metadata.type == "discovery"))
      | "  - " + .spec.name' >&2 || true
