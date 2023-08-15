#!/bin/bash

usage() {
  echo "USAGE: lint-configs.sh output.yaml [output2.yaml...]"
  echo ""
  echo "Uses Grafana Agent to lint the generated river config"
}

export AGENT_MODE=flow
for file in "$@";
do
  echo "Linting Agent config in ${file}...";
  if ! grafana-agent fmt "${file}" > /dev/null; then
    exit 1
  fi
done
