#!/usr/bin/env bash
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/utils.sh"
source "${PARENT_DIR}/scripts/includes/logging.sh"

usage() {
  echo "USAGE: lint-configs.sh [--public-preview] output.alloy [output2.alloy...]"
  echo ""
  echo "Uses Grafana Alloy to lint the generated configuration"
  echo "  --public-preview    - Switch to the public-preview stability level"
}

# check to see if alloy is installed
if [[ "$(command -v alloy || true)" = "" ]]; then
  emergency "alloy is required if running lint locally, see: (https://grafana.com/docs/alloy/latest/) or run: brew install grafana-alloy";
fi

# determine whether or not the script is called directly or sourced
(return 0 2>/dev/null) && sourced=1 || sourced=0

# Initialize a flag variable
FORMAT="console"
STABILITY_LEVEL=generally-available

# Loop through all arguments
for arg in "$@"
do
  if [[ "${arg}" == "--format=checkstyle" ]]; then
    # Set the flag to true if the specific argument is found
    FORMAT="checkstyle"
    break
  fi
done

if [[ "${FORMAT}" == "console" ]]; then
  # output the heading
  heading "Kubernetes Monitoring Helm" "Performing Alloy Lint"
fi

statusCode=0
checkstyle='<?xml version="1.0" encoding="utf-8"?><checkstyle version="4.3">'

# Inject a component that utilizes Kubernetes discovery, so we know that the config will fail in a predictable way.
k8sDiscovery='discovery.kubernetes "lint_config_component" { role = "nodes" }'

for file in "$@";
do
  if grep "${file}" -e "remotecfg {" >/dev/null; then
    STABILITY_LEVEL=public-preview
  fi
  if grep "${file}" -e "livedebugging {" >/dev/null; then
    STABILITY_LEVEL=experimental
  fi

  # if the file doesn't exist skip it
  if [[ ! -f "${file}" ]]; then
   continue
  fi

  # add file to checkstyle output
  checkstyle="${checkstyle}<file name=\"${file}\">"
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
    # output to console only if the format is console
    if [[ "${FORMAT}" == "console" ]]; then
      echo -e "\\x1b[32m${file}\\x1b[0m: no issues found"
    fi
    checkstyle="${checkstyle}</file>"
  else
    # output to console only if the format is console
    if [[ "${FORMAT}" == "console" ]]; then
      echo -e "\\x1b[31m${file}\\x1b[0m: issues found"
    fi

    # output alloy fmt errors
    if [[ "${fmtCode}" != 0 ]]; then
      # loop each found issue
      while IFS= read -r row; do
        # Process each line here
        line=$(echo "${row}" | awk -F ':' '{print $2}')
        column=$(echo "${row}" | awk -F ':' '{print $3}')
        error=$(echo "${row}" | cut -d':' -f4- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed -e 's/"/\&quot;/g' | xargs || true)
        checkstyle="${checkstyle}<error line=\"${line}\" column=\"${column}\" severity=\"error\" message=\"${error}\" source=\"alloy\"/>"
        # output to console only if the format is console
        if [[ "${FORMAT}" == "console" ]]; then
          echo "  - ${row}"
        fi
      done <<< "${fmt_output}"
    fi

    # output alloy run errors
    if [[ "${run_code}" != 0 ]]; then
      # loop each found issue
      while IFS= read -r row; do
        if [[ "${row}" =~ "Error: " ]]; then
          # Process each line here
          line=$(echo "${row}" | awk -F ':' '{print $2}')
          column=$(echo "${row}" | awk -F ':' '{print $3}')
          error=$(echo "${row}" | cut -d':' -f5- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed -e 's/"/\&quot;/g' | xargs || true)
          checkstyle="${checkstyle}<error line=\"${line}\" column=\"${column}\" severity=\"error\" message=\"${error}\" source=\"alloy\"/>"
          # output to console only if the format is console
          if [[ "${FORMAT}" == "console" ]]; then
            echo "  - ${row}"
          fi
        fi
      done <<< "${run_output}"
    fi

    checkstyle="${checkstyle}</file>"

    if [[ "${statusCode}" == 0 ]]; then
      statusCode=1
    fi
  fi
done

checkstyle="${checkstyle}</checkstyle>"

if [[ "${FORMAT}" == "checkstyle" ]]; then
  echo -n "${checkstyle}"
else
  echo ""
  echo ""
fi

# if the script was called by another, send a valid exit code
if [[ "${sourced}" == "1" ]]; then
  return "${statusCode}"
else
  exit "${statusCode}"
fi
