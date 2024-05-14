#!/bin/bash

usage() {
  echo "USAGE: lint-configs.sh [--public-preview] output.alloy [output2.alloy...]"
  echo ""
  echo "Uses Grafana Alloy to lint the generated configuration"
  echo "  --public-preview    - Switch to the public-preview stability level"
}

STABILITY_LEVEL=generally-available

for file in "$@";
do
  if [[ "${file}" == "--public-preview" ]]; then
    STABILITY_LEVEL=public-preview
  fi

  # Skip missing or empty files
  if [[ ! -s "${file}" ]]; then
    continue
  fi

  echo "Linting Alloy config in ${file}...";

  # Use the fmt action to validate the config file's syntax
  if ! alloy fmt "${file}" > /dev/null; then
    exit 1
  fi

  # Attempt to run with the config file.
  # A "successful" attempt will fail because we're not running in Kubernetes
  output=$(alloy run --stability.level "${STABILITY_LEVEL}" "${file}" 2>&1)
  if ! echo "${output}" | grep "KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT must be defined" >/dev/null; then
    echo "${output}"
    exit 1
  fi
done
