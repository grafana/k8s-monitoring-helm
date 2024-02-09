#!/bin/bash

usage() {
  echo "USAGE: lint-configs.sh output.yaml [output2.yaml...]"
  echo ""
  echo "Uses Grafana Agent to lint the generated river config"
}

export AGENT_MODE=flow
for file in "$@";
do
  # Skip missing or empty files
  if [ ! -s "${file}" ]; then
    continue
  fi

  echo "Linting Agent config in ${file}...";

  # Use the fmt action to validate the config file's river format
  if ! grafana-agent fmt "${file}" > /dev/null; then
    exit 1
  fi

  # Attempt to run with the config file.
  # A "successful" attempt will fail because we're not running in Kubernetes
  output=$(grafana-agent run "${file}" 2>&1)
  if ! echo "${output}" | grep "KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT must be defined" >/dev/null; then
    echo "${output}"
    exit 1
  fi
done
