#!/bin/bash
set -o pipefail

script_name="${0##*/}"
if [[ "${script_name}" == "bash" || "${script_name}" == "-bash" ]]; then
  script_name="script.sh"
fi

DefaultWatchTimeout=30s
ManifestRequestThrottling=0.1s
WatchRestartDelay=5

usage() {
  echo "Usage: ${script_name} [OPTIONS]"
  echo ""
  echo "Collects Kubernetes manifests and saves them as files."
  echo ""
  echo "Resource manifests are stored at \${MANIFEST_DIR}/<kind>/<namespace>/<name>.json"
  echo ""
  echo "Requires the MANIFEST_DIR environment variable to be set to the target directory."
  echo ""
  echo "Options:"
  echo "  -k, --kind <kind>        Kubernetes resource kind passed to \"kubectl get\"."
  echo "                           Default: pods"
  echo "  -n, --namespace <name>   Namespace to scan. When omitted, all namespaces"
  echo "                           are scanned."
  echo "  -f, --filters <list>     Comma or space separated list of jq selectors to drop"
  echo "                           from the resource JSON. Default: \".status\""
  echo "  --watch-timeout <time>   How long to keep a watch open before restarting."
  echo "                           Default: ${DefaultWatchTimeout}s."
  echo "  -h, --help               Show this help message."
}

kind="pods"
kindDir="pods"
namespace=""
filters=(".status")
watchTimeout="${DefaultWatchTimeout}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -k|--kind)
      if [[ $# -lt 2 ]]; then
        echo "Error: --kind requires an argument." >&2
        usage
        exit 1
      fi
      kind="$2"
      kindDir="${kind,,}"  # Forces lowercase
      kindDir="${kindDir//[^a-z0-9._-]/_}"  # Replace special characters with _
      shift 2
      ;;
    -n|--namespace)
      if [[ $# -lt 2 ]]; then
        echo "Error: --namespace requires an argument." >&2
        usage
        exit 1
      fi
      namespace="$2"
      shift 2
      ;;
    -f|--filters)
      if [[ $# -lt 2 ]]; then
        echo "Error: --filters requires an argument." >&2
        usage
        exit 1
      fi

      filters=()
      sanitized="${2//$'\n'/ }"
      sanitized="${sanitized//,/ }"
      read -ra parsedFilters <<< "${sanitized}"
      for filter in "${parsedFilters[@]}"; do
        [[ -n "${filter}" ]] || continue
        filters+=("${filter}")
      done
      jqFilters="$(build_jq_filter "${filters[@]}")"

      shift 2
      ;;
    --watch-timeout)
      if [[ $# -lt 2 ]]; then
        echo "Error: --watch-timeout requires an argument." >&2
        usage
        exit 1
      fi
      watchTimeout="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${MANIFEST_DIR:-}" ]]; then
  echo "Error: MANIFEST_DIR environment variable must be set." >&2
  exit 1
fi

mkdir -p "${MANIFEST_DIR}"

build_jq_filter() {
  local program="."
  for filter in "$@"; do
    [[ -n "${filter}" ]] || continue
    program+=" | del(${filter})"
  done
  printf '%s' "${program}"
}

jqFilters="$(build_jq_filter "${filters[@]}")"

collect_manifest() {
  local namespace="$1"
  local resourceName="$2"

  [[ -n "${namespace}" && -n "${resourceName}" ]] || return 0

  local namespaceDir="${MANIFEST_DIR}/${kindDir}/${namespace}"
  mkdir -p "${namespaceDir}"

  local outputFile="${namespaceDir}/${resourceName}.json"
  local tmpFile="${outputFile}.tmp"

  if kubectl get "${kind}" --namespace "${namespace}" "${resourceName}" -o json \
    | jq --compact-output "${jqFilters}" > "${tmpFile}"; then
    if [[ ! -f "${outputFile}" ]] || ! cmp -s "${tmpFile}" "${outputFile}"; then
      echo "[INFO] ${kind}: Saving manifest for \"${namespace}/${resourceName}\""
      mv "${tmpFile}" "${outputFile}"
    else
      echo "[DEBUG] ${kind}: No changes to manifest for \"${namespace}/${resourceName}\""
      rm -f "${tmpFile}"
    fi
  else
    echo "[ERROR] ${kind}: Failed to collect manifest for ${kind} ${namespace}/${resourceName}" >&2
    rm -f "${tmpFile}"
  fi
}

remove_manifest() {
  local namespace="$1"
  local resourceName="$2"

  [[ -n "${namespace}" && -n "${resourceName}" ]] || return

  local outputFile="${MANIFEST_DIR}/${kindDir}/${namespace}/${resourceName}.json"
  if [[ -f "${outputFile}" ]]; then
    rm -f "${outputFile}"
    echo "[INFO] ${kind}: Removed manifest for \"${namespace}/${resourceName}\""
  fi
}

handle_watch_event() {
  local eventType="$1"
  local namespace="$2"
  local resourceName="$3"

  [[ -n "${eventType}" && -n "${namespace}" && -n "${resourceName}" ]] || return

  echo "[DEBUG] ${kind}: ${eventType} event for ${namespace}/${resourceName}"
  case "${eventType}" in
    ADDED|MODIFIED)
      collect_manifest "${namespace}" "${resourceName}"
      ;;
    DELETED)
      remove_manifest "${namespace}" "${resourceName}"
      ;;
    *)
      ;;
  esac
}

watch_resources() {
  local kubectlArgs=()
  if [[ -n "${namespace}" ]]; then
    kubectlArgs=(--namespace "${namespace}")
    echo "[INFO] ${kind}: Watching namespace ${namespace}"
  else
    kubectlArgs=(--all-namespaces)
    echo "[INFO] ${kind}: Watching all namespaces"
  fi

  while true; do
    if ! timeout --foreground "${watchTimeout}" kubectl get "${kind}" "${kubectlArgs[@]}" --watch --output-watch-events -o json \
      | jq --unbuffered -r 'select(.object.metadata.namespace != null and .object.metadata.name != null and .type != null) | "\(.type) \(.object.metadata.namespace) \(.object.metadata.name)"' \
      | while read -r eventType namespace resourceName; do
          handle_watch_event "${eventType}" "${namespace}" "${resourceName}"
          sleep "${ManifestRequestThrottling}"  # Throttle the requests
        done; then
      echo "[WARN] ${kind}: Watch ended. Restarting in ${WatchRestartDelay} seconds." >&2
      sleep "${WatchRestartDelay}"
    fi
  done
}

watch_resources
