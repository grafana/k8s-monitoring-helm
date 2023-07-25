#!/bin/bash

usage() {
  echo "USAGE: lint-configs.sh output.yaml [output2.yaml...]"
  echo ""
  echo "Uses Grafana Agent to lint the generated river config"
}

export AGENT_MODE=flow
configMapName=k8smon-grafana-agent

for file in "$@";
do
  echo "Linting Agent config in ${file}...";
  if ! grafana-agent fmt <(yq -r "select(.metadata.name==\"${configMapName}\") | .data[\"config.river\"] | select( . != null )" "${file}") > /dev/null; then
    exit 1
  fi
done
