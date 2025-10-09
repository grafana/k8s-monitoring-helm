#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CHART_DIR=$(realpath "${SCRIPT_DIR}/..")

PYROSCOPE_SECRET="op://Kubernetes Monitoring/helmchart Pyroscope"

usage() {
  cat <<'USAGE'
Usage: generate-profiles.sh [options] <values.yaml> [values.yaml ...]

Options
  --upload      Upload generated profiles to Pyroscope via profilecli.
  -h, --help    Show this help message.

Examples
  ./generate-profiles.sh docs/examples/features/cluster-metrics/default/values.yaml
  ./generate-profiles.sh --upload docs/examples/features/cluster-metrics/default/values.yaml
USAGE
}

upload=false
case "$1" in
  --upload)
    upload=true
    shift
    ;;
  -h|-help|--help)
    usage
    exit 0
    ;;
esac

valuesFile="$1"
if [[ ! -f "${valuesFile}" ]]; then
  echo "Error: values.yaml file '${valuesFile}' does not exist."
  usage
  exit 1
fi

cpuProfile="$(dirname "${valuesFile}")/helm.cpu.pb.gz"
memProfile="$(dirname "${valuesFile}")/helm.mem.pb.gz"
HELM_PPROF_CPU_PROFILE="${cpuProfile}" \
HELM_PPROF_MEM_PROFILE="${memProfile}" \
  helm template k8smon "${CHART_DIR}" -f "${valuesFile}" >/dev/null

if [[ "${upload}" == true ]]; then
  chartName="$(yq eval '.name' "${CHART_DIR}/Chart.yaml")"
  chartVersion="$(yq eval '.version' "${CHART_DIR}/Chart.yaml")"
  if [[ -z ${PROFILECLI_URL:-} ]]; then
    PROFILECLI_URL="$(op --account grafana.1password.com read "${PYROSCOPE_SECRET}/website")"
    export PROFILECLI_URL
  fi
  if [[ -z ${PROFILECLI_USERNAME:-} ]]; then
    PROFILECLI_USERNAME="$(op --account grafana.1password.com read "${PYROSCOPE_SECRET}/username")"
    export PROFILECLI_USERNAME
  fi
  if [[ -z ${PROFILECLI_PASSWORD:-} ]]; then
    PROFILECLI_PASSWORD="$(op --account grafana.1password.com read "${PYROSCOPE_SECRET}/password")"
    export PROFILECLI_PASSWORD
  fi

  echo "Uploading cpu profile..."
  profilecli upload \
    --override-timestamp \
    --extra-labels="service_instance_id=$(yq eval '.cluster.name' "${valuesFile}")" \
    --extra-labels="service_name=helm" \
    --extra-labels="chart=${chartName}" \
    --extra-labels="version=${chartVersion}" \
    "$cpuProfile"

  echo "Uploading memory profile..."
  profilecli upload \
    --override-timestamp \
    --extra-labels="service_instance_id=$(yq eval '.cluster.name' "${valuesFile}")" \
    --extra-labels="service_name=helm" \
    --extra-labels="chart=${chartName}" \
    --extra-labels="version=${chartVersion}" \
    "$memProfile"
fi
