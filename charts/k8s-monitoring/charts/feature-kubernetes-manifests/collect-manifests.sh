#!/bin/bash
set -o pipefail

script_name="${0##*/}"
if [[ "${script_name}" == "bash" || "${script_name}" == "-bash" ]]; then
  script_name="script.sh"
fi

DefaultRefreshInterval=60

usage() {
  echo "Usage: ${script_name} [OPTIONS]"
  echo ""
  echo "Collects Kubernetes manifests and saves them as files."
  echo ""
  echo "Pod manifests are stored at \${MANIFEST_DIR}/pods/<namespace>/<pod>.json"
  echo ""
  echo "Requires the MANIFEST_DIR environment variable to be set to the target directory."
  echo ""
  echo "Options:"
  echo "  -n, --namespaces <list>  Comma or space separated list of namespaces to scan."
  echo "                           When omitted, all namespaces are scanned."
  echo "  -p, --pod-filters <list> Comma or space separated list of jq selectors to drop"
  echo "                           from the pod JSON. Default: \".status\""
  echo "  --refresh-interval <sec> How frequently to refresh manifests. Default: \"${DefaultRefreshInterval}\""
  echo "  -h, --help               Show this help message."
}

podNamespaces=()
podFilters=(".status")
refreshInterval="${DefaultRefreshInterval}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespaces)
      if [[ $# -lt 2 ]]; then
        echo "Error: --namespaces requires an argument." >&2
        usage
        exit 1
      fi

      sanitized="${2//$'\n'/ }"
      sanitized="${sanitized//,/ }"
      read -ra parsedNamespaces <<< "${sanitized}"
      for ns in "${parsedNamespaces[@]}"; do
        [[ -n "${ns}" ]] || continue
        podNamespaces+=("${ns}")
      done

      shift 2
      ;;
    -p|--pod-filters)
      if [[ $# -lt 2 ]]; then
        echo "Error: --pod-filters requires an argument." >&2
        usage
        exit 1
      fi

      podFilters=()
      sanitized="${2//$'\n'/ }"
      sanitized="${sanitized//,/ }"
      read -ra parsedPodFilters <<< "${sanitized}"
      for filter in "${parsedPodFilters[@]}"; do
        [[ -n "${filter}" ]] || continue
        podFilters+=("${filter}")
      done

      shift 2
      ;;
    --refresh-interval)
      if [[ $# -lt 2 ]]; then
        echo "Error: --pod-refresh requires an argument." >&2
        usage
        exit 1
      fi
      refreshInterval="$2"
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

if [[ -z "${namespaces_arg}" && -n "${NAMESPACES:-}" ]]; then
  namespaces_arg="${NAMESPACES}"
fi

if [[ -z "${MANIFEST_DIR:-}" ]]; then
  echo "MANIFEST_DIR environment variable must be set." >&2
  exit 1
fi

mkdir -p "${MANIFEST_DIR}"

watchPids=()

build_jq_filter() {
  local program="."
  for filter in "$@"; do
    [[ -n "${filter}" ]] || continue
    program+=" | del(${filter})"
  done
  printf '%s' "${program}"
}

collect_pod_manifest() {
  local namespace="$1"
  local podName="$2"

  [[ -n "${namespace}" && -n "${podName}" ]] || return 0

  local namespace_dir="${MANIFEST_DIR}/pods/${namespace}"
  mkdir -p "${namespace_dir}"

  local outputFile="${namespace_dir}/${podName}.json"
  local tmpFile="${outputFile}.tmp"

  pod_output_filter="$(build_jq_filter "${podFilters[@]}")"
  if kubectl get pod --namespace "${namespace}" "${podName}" -o json | jq --compact-output "${pod_output_filter}" > "${tmpFile}"; then
    if [[ ! -f "${outputFile}" ]] || ! cmp -s "${tmpFile}" "${outputFile}"; then
      echo "Storing pod manifest \"${namespace}/${podName}\""
      mv "${tmpFile}" "${outputFile}"
    else
      echo "No changes to pod manifest \"${namespace}/${podName}\""
      rm -f "${tmpFile}"
    fi
  else
    echo "Failed to collect manifest for pod ${namespace}/${podName}" >&2
    rm -f "${tmpFile}"
  fi
}

remove_pod_manifest() {
  local namespace="$1"
  local podName="$2"

  [[ -n "${namespace}" && -n "${podName}" ]] || return

  local outputFile="${MANIFEST_DIR}/pods/${namespace}/${podName}.json"
  if [[ -f "${outputFile}" ]]; then
    rm -f "${outputFile}"
    echo "Removed pod manifest \"${namespace}/${podName}\""
  fi
}

collect_all_pod_manifests() {
  if podEntries=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}'); then
    while IFS= read -r entry; do
      [[ -n "${entry}" ]] || continue
      read -r namespace podName _ <<< "${entry}"
      if [[ -z "${namespace}" || -z "${podName}" ]]; then
        continue
      fi
      collect_pod_manifest "${namespace}" "${podName}"
    done <<< "${podEntries}"
  else
    echo "Failed to list pods across all namespaces." >&2
  fi
}

collect_pod_manifests_by_namespace() {
  for namespace in "${podNamespaces[@]}"; do
    [[ -n "${namespace}" ]] || continue

    if ! podNames=$(kubectl get pods --namespace "${namespace}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); then
      echo "Failed to list pods in namespace ${namespace}" >&2
      continue
    fi

    while IFS= read -r podName; do
      [[ -n "${podName}" ]] || continue
      collect_pod_manifest "${namespace}" "${podName}"
    done <<< "${podNames}"
  done
}

refresh_pod_manifests() {
  if [[ ${#podNamespaces[@]} -eq 0 ]]; then
    collect_all_pod_manifests
  else
    collect_pod_manifests_by_namespace
  fi
}

handle_pod_watch_event() {
  local eventType="$1"
  local namespace="$2"
  local podName="$3"

  [[ -n "${event_type}" && -n "${namespace}" && -n "${podName}" ]] || return

  echo "Pod event: ${namespace}/${podName}: ${eventType}"
  case "${eventType}" in
    ADDED|MODIFIED)
      collect_pod_manifest "${namespace}" "${podName}"
      ;;
    DELETED)
      remove_pod_manifest "${namespace}" "${podName}"
      ;;
    *)
      ;;
  esac
}

watch_pods() {
  local kubectl_args=("$@")
  echo "Starting pod watcher: kubectl get pods ${kubectl_args[*]}"

  while true; do
    if ! kubectl get pods "${kubectl_args[@]}" --watch --output-watch-events -o json \
      | jq --unbuffered -r 'select(.object.metadata.namespace != null and .object.metadata.name != null and .type != null) | "\(.type) \(.object.metadata.namespace) \(.object.metadata.name)"' \
      | while read -r eventType namespace podName; do
          handle_pod_watch_event "${eventType}" "${namespace}" "${podName}"
        done; then
      echo "Pod watch ended unexpectedly for args: ${kubectl_args[*]}" >&2
      sleep 5
    fi
  done
}

start_pod_watches() {
  if [[ ${#podNamespaces[@]} -eq 0 ]]; then
    watch_pods "--all-namespaces" &
    watchPids+=("$!")
  else
    for namespace in "${podNamespaces[@]}"; do
      [[ -n "${namespace}" ]] || continue
      watch_pods "--namespace" "${namespace}" &
      watchPids+=("$!")
    done
  fi
}

stop_pod_watches() {
  if [[ ${#watchPids[@]} -eq 0 ]]; then
    return
  fi

  for pid in "${watchPids[@]}"; do
    [[ -n "${pid}" ]] || continue
    kill "${pid}" 2>/dev/null || true
  done

  watchPids=()
}

trap stop_pod_watches EXIT

start_pod_watches

loop_delay="${POD_LOOP_DELAY:-5}"
lastFullSync=0

while true; do
  currentTime=$(date +%s)
  if (( currentTime - lastFullSync >= refreshInterval )); then
    refresh_pod_manifests
    lastFullSync="${currentTime}"
  fi

  sleep "${loop_delay}"
done
