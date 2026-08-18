#!/usr/bin/env bash
# Usage: set-app-observability.sh <cluster> <namespace> <true|false>
set -euo pipefail

CLUSTER="${1:?usage: set-app-observability.sh <cluster> <namespace> <true|false>}"
NAMESPACE="${2:?namespace required}"
AUTOINSTRUMENT="${3:?true|false required}"

FM_URL="${GRAFANA_CLOUD_FM_URL:-https://fleet-management-prod-008.grafana.net}"
FM_USER="${GRAFANA_CLOUD_FLEET_MGMT_USER:?GRAFANA_CLOUD_FLEET_MGMT_USER not set}"
FM_TOKEN="${GRAFANA_CLOUD_TOKEN:?set GRAFANA_CLOUD_TOKEN to a fleet-management:write cloud token}"
MIMIR_URL="${GRAFANA_CLOUD_MIMIR_PUSH_URL:-https://prometheus-prod-13-prod-us-east-0.grafana.net/api/prom/push}"
MIMIR_USER="${GRAFANA_CLOUD_METRICS_USERNAME:?GRAFANA_CLOUD_METRICS_USERNAME not set}"
OTLP_URL="${GRAFANA_CLOUD_OTLP_URL:-https://otlp-gateway-prod-us-east-0.grafana.net/otlp}"
OTLP_USER="${GRAFANA_CLOUD_OTLP_USERNAME:-${MIMIR_USER}}"

body="$(jq -n \
  --arg mu "${MIMIR_URL}" --arg mun "${MIMIR_USER}" \
  --arg ou "${OTLP_URL}" --arg oun "${OTLP_USER}" \
  --arg cn "${CLUSTER}" --arg ns "${NAMESPACE}" --argjson ai "${AUTOINSTRUMENT}" \
  '{mimir_url:$mu, mimir_username:$mun, otlp_url:$ou, otlp_username:$oun,
    cluster:{name:$cn, namespaces:[{name:$ns, autoinstrument:$ai}]}}')"

curl -sS --fail-with-body --retry 4 --retry-connrefused --retry-delay 2 \
  --connect-timeout 10 --max-time 60 \
  -u "${FM_USER}:${FM_TOKEN}" -H "Content-Type: application/json" \
  -X POST "${FM_URL}/instrumentation.v1.InstrumentationService/SetAppInstrumentation" \
  -d "${body}" >/dev/null
