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
export k8sDiscovery='discovery.kubernetes "lint_config_component" { role = "nodes" }'

lint_file() {
  local file="$1"

  # if the file doesn't exist skip it
  if [[ ! -f "${file}" ]]; then
    return 0
  fi

  local STABILITY_LEVEL=generally-available
  if grep "${file}" -e "otelcol.receiver.filelog" >/dev/null; then
    STABILITY_LEVEL=public-preview
  fi
  if grep "${file}" -e "otelcol.storage.file" >/dev/null; then
    STABILITY_LEVEL=public-preview
  fi
  if grep "${file}" -e "otelcol.exporter.debug" >/dev/null; then
    STABILITY_LEVEL=experimental
  fi
  if grep "${file}" -e "prometheus.enrich" >/dev/null; then
    STABILITY_LEVEL=experimental
  fi
  if grep "${file}" -e "loki.enrich" >/dev/null; then
    STABILITY_LEVEL=experimental
  fi
  if grep "${file}" -e "pyroscope.enrich" >/dev/null; then
    STABILITY_LEVEL=experimental
  fi

  local fmt_output fmtCode run_code run_output file_is_empty
  fmt_output=$(alloy fmt "${file}" 2>&1)
  fmtCode="$?"
  fmt_output=$(echo "${fmt_output}" | grep -v "Error: encountered errors during formatting")
  # Attempt to run with the config file.
  run_code=0
  run_output=""
  file_is_empty=$(grep -cve '^\s*$' "${file}" || true)
  # make sure the file is not empty, otherwise alloy will actually run and not exit
  if [[ "${file_is_empty}" != 0 ]]; then
    run_output=$(alloy run --stability.level "${STABILITY_LEVEL}" <(cat "${file}"; echo "${k8sDiscovery}") 2>&1)
    # A "successful" attempt will fail because we're not running in Kubernetes
    if ! echo "${run_output}" | grep "KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT must be defined" >/dev/null; then
      run_code=1
    fi
  fi

  # Buffer this file's output so parallel invocations don't interleave.
  local report
  if [[ "${fmtCode}" == 0 ]] && [[ "${run_code}" == 0 ]]; then
    report=$(echo -e "\\x1b[32m${file}\\x1b[0m: no issues found")
    echo "${report}"
    return 0
  fi

  report=$(echo -e "\\x1b[31m${file}\\x1b[0m: issues found")

  # output alloy fmt errors
  if [[ "${fmtCode}" != 0 ]]; then
    while IFS= read -r row; do
      report+=$'\n'"  - ${row}"
    done <<< "${fmt_output}"
  fi

  # output alloy run errors
  if [[ "${run_code}" != 0 ]]; then
    while IFS= read -r row; do
      if [[ "${row}" =~ "Error: " ]]; then
        report+=$'\n'"  - ${row}"
      fi
    done <<< "${run_output}"
  fi

  echo "${report}"
  return 1
}
export -f lint_file

# Lint each file in parallel. xargs exits non-zero if any invocation fails.
printf '%s\n' "$@" | xargs -r -P "$(nproc 2>/dev/null || echo 4)" -I {} bash -c 'lint_file "$@"' _ {}
