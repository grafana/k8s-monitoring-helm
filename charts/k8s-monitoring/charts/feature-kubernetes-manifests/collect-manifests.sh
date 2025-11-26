#!/bin/bash
set -o pipefail

script_name="${0##*/}"
if [[ "${script_name}" == "bash" || "${script_name}" == "-bash" ]]; then
  script_name="script.sh"
fi

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
  echo "                           from the pod JSON."
  echo "                           Default: .status"
  echo "  -h, --help               Show this help message."
}

namespaces_arg=""
pod_filters_arg=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespaces)
      if [[ $# -lt 2 ]]; then
        echo "Error: --namespaces requires an argument." >&2
        usage
        exit 1
      fi
      namespaces_arg="$2"
      shift 2
      ;;
    -p|--pod-filters)
      if [[ $# -lt 2 ]]; then
        echo "Error: --pod-filters requires an argument." >&2
        usage
        exit 1
      fi
      pod_filters_arg="$2"
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

pod_namespaces=()
if [[ -n "${namespaces_arg}" ]]; then
  sanitized="${namespaces_arg//$'\n'/ }"
  sanitized="${sanitized//,/ }"
  read -ra parsed_namespaces <<< "${sanitized}"
  for ns in "${parsed_namespaces[@]}"; do
    [[ -n "${ns}" ]] || continue
    pod_namespaces+=("${ns}")
  done
fi

default_pod_filters=(".status")
pod_filters=()
if [[ -n "${pod_filters_arg}" ]]; then
  sanitized="${pod_filters_arg//$'\n'/ }"
  sanitized="${sanitized//,/ }"
  read -ra parsed_pod_filters <<< "${sanitized}"
  for filter in "${parsed_pod_filters[@]}"; do
    [[ -n "${filter}" ]] || continue
    pod_filters+=("${filter}")
  done
fi

if [[ ${#pod_filters[@]} -eq 0 ]]; then
  pod_filters=("${default_pod_filters[@]}")
fi

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
  local pod_name="$2"
  pod_output_filter="$(build_jq_filter "${pod_filters[@]}")"

  [[ -n "${namespace}" && -n "${pod_name}" ]] || return 0

  local namespace_dir="${MANIFEST_DIR}/pods/${namespace}"
  mkdir -p "${namespace_dir}"

  local output_file="${namespace_dir}/${pod_name}.json"
  local tmp_file="${output_file}.tmp"

  if kubectl get pod --namespace "${namespace}" "${pod_name}" -o json | jq --compact-output "${pod_output_filter}" > "${tmp_file}"; then
    echo "Storing pod manifest \"${namespace}/${pod_name}\""
    mv "${tmp_file}" "${output_file}"
  else
    echo "Failed to collect manifest for pod ${namespace}/${pod_name}" >&2
    rm -f "${tmp_file}"
  fi
}

collect_all_pod_manifests() {
  if pod_entries=$(kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}'); then
    while IFS= read -r entry; do
      [[ -n "${entry}" ]] || continue
      read -r namespace pod_name _ <<< "${entry}"
      if [[ -z "${namespace}" || -z "${pod_name}" ]]; then
        continue
      fi
      collect_pod_manifest "${namespace}" "${pod_name}"
    done <<< "${pod_entries}"
  else
    echo "Failed to list pods across all namespaces." >&2
  fi
}

collect_pod_manifests_by_namespace() {
  for namespace in "${pod_namespaces[@]}"; do
    [[ -n "${namespace}" ]] || continue

    if ! pod_names=$(kubectl get pods --namespace "${namespace}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); then
      echo "Failed to list pods in namespace ${namespace}" >&2
      continue
    fi

    while IFS= read -r pod_name; do
      [[ -n "${pod_name}" ]] || continue
      collect_pod_manifest "${namespace}" "${pod_name}"
    done <<< "${pod_names}"
  done
}

while true; do
  if [[ ${#pod_namespaces[@]} -eq 0 ]]; then
    collect_all_pod_manifests
  else
    collect_pod_manifests_by_namespace
  fi

  sleep 60
done
