#!/usr/bin/env bash

usage() {
  echo "USAGE: lint-alloy.sh [--public-preview] output.alloy [output2.alloy...]"
  echo ""
  echo "Uses Grafana Alloy to lint the generated configuration"
}

# check to see if alloy is installed
if [[ "$(command -v alloy || true)" = "" ]]; then
  echo "Error: alloy is required if running lint locally, see: (https://grafana.com/docs/alloy/latest/) or run: brew install grafana-alloy";
  exit 1
fi

# Initialize a flag variable
STABILITY_LEVEL=generally-available

statusCode=0

# Inject a component that utilizes Kubernetes discovery, so we know that the config will fail in a predictable way.
k8sDiscovery='discovery.kubernetes "lint_config_component" { role = "nodes" }'

for file in "$@";
do
  # if the file doesn't exist skip it
  if [[ ! -f "${file}" ]]; then
   continue
  fi

  if grep "${file}" -e "otelcol.receiver.filelog" >/dev/null; then
    STABILITY_LEVEL=public-preview
  fi
  if grep "${file}" -e "otelcol.exporter.debug" >/dev/null; then
    STABILITY_LEVEL=experimental
  fi

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

  # if the current code is 0, output the file name for logging purposes
  if [[ "${fmtCode}" == 0 ]] && [[ "${run_code}" == 0 ]]; then
    echo -e "\\x1b[32m${file}\\x1b[0m: no issues found"
  else
    echo -e "\\x1b[31m${file}\\x1b[0m: issues found"

    # output alloy fmt errors
    if [[ "${fmtCode}" != 0 ]]; then
      # loop each found issue
      while IFS= read -r row; do
        echo "  - ${row}"
      done <<< "${fmt_output}"
    fi

    # output alloy run errors
    if [[ "${run_code}" != 0 ]]; then
      # loop each found issue
      while IFS= read -r row; do
        if [[ "${row}" =~ "Error: " ]]; then
          echo "  - ${row}"
        fi
      done <<< "${run_output}"
    fi

    if [[ "${statusCode}" == 0 ]]; then
      statusCode=1
    fi
  fi
done
