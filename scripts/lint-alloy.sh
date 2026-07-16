#!/usr/bin/env bash

usage() {
  echo "USAGE: lint-alloy.sh config.alloy [config2.alloy...]"
  echo ""
  echo "Uses Grafana Alloy to lint the generated configuration"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# check to see if alloy is installed
if [[ "$(command -v alloy || true)" = "" ]]; then
  echo "Error: alloy is required if running lint locally, see: (https://grafana.com/docs/alloy/latest/) or run: brew install grafana-alloy";
  exit 1
fi

# Inject a component that utilizes Kubernetes discovery, so we know that the config will fail in a predictable way.
k8sDiscovery='discovery.kubernetes "lint_config_component" { role = "nodes" }'

lint_alloy_file() {
  local file="$1"

  # if the file doesn't exist skip it
  if [[ ! -f "${file}" ]]; then
    return 0
  fi

  # Raise the stability level to match the least stable component used in the config.
  local stability_level=generally-available
  if grep -qF -e "otelcol.exporter.debug" -e "prometheus.enrich" -e "loki.enrich" -e "pyroscope.enrich" "${file}"; then
    stability_level=experimental
  elif grep -qF -e "otelcol.receiver.filelog" -e "otelcol.storage.file" "${file}"; then
    stability_level=public-preview
  fi

  local fmt_output fmtCode
  fmt_output=$(alloy fmt "${file}" 2>&1)
  fmtCode="$?"
  fmt_output=$(echo "${fmt_output}" | grep -v "Error: encountered errors during formatting")

  # Attempt to run with the config file.
  local run_code=0
  local run_output=""
  # make sure the file is not empty, otherwise alloy will actually run and not exit
  if grep -qve '^\s*$' "${file}"; then
    run_code=1
    local attempt port
    for attempt in 1 2 3; do
      port=$(( 10000 + (($$ + attempt * 1009) % 40000) ))
      run_output=$(alloy run --server.http.listen-addr="127.0.0.1:${port}" --stability.level "${stability_level}" <(cat "${file}"; echo "${k8sDiscovery}") 2>&1)
      # A "successful" attempt will fail because we're not running in Kubernetes
      if echo "${run_output}" | grep -q "KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT must be defined"; then
        run_code=0
        break
      fi
    done
  fi

  # if the current code is 0, output the file name for logging purposes
  if [[ "${fmtCode}" == 0 ]] && [[ "${run_code}" == 0 ]]; then
    printf '\x1b[32m%s\x1b[0m: no issues found\n' "${file}"
    return 0
  fi

  # Buffer the failure report so parallel output does not interleave.
  local buffer
  buffer=$(printf '\x1b[31m%s\x1b[0m: issues found' "${file}")
  if [[ "${fmtCode}" != 0 ]]; then
    buffer+=$'\n'"$(printf '%s\n' "${fmt_output}" | sed 's/^/  - /')"
  fi
  if [[ "${run_code}" != 0 ]]; then
    buffer+=$'\n'"$(printf '%s\n' "${run_output}" | grep 'Error: ' | sed 's/^/  - /')"
  fi

  printf '%s\n' "${buffer}"
  return 1
}

# Internal entrypoint used by the parallel dispatcher below to lint a single file.
if [[ "${1:-}" == "--lint-one" ]]; then
  lint_alloy_file "$2"
  exit "$?"
fi

if [[ "$#" -eq 0 ]]; then
  exit 0
fi

PARALLELISM="${LINT_ALLOY_PARALLELISM:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

# Lint each file in parallel. xargs exits non-zero if any invocation reports issues.
if ! printf '%s\0' "$@" | xargs -0 -P "${PARALLELISM}" -I{} "$0" --lint-one {}; then
  exit 1
fi
exit 0
