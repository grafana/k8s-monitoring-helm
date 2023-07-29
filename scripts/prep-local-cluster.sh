#!/bin/bash

CLUSTER_NAME=k8smon-test-cluster

MIMIR_VALUES=".github/configs/mimir.yaml"
LOKI_VALUES=".github/configs/loki.yaml"
TEMPO_VALUES=".github/configs/tempo.yaml"
GRAFANA_VALUES=".github/configs/grafana.yaml"

set -eo pipefail

if ! kind get clusters | grep "${CLUSTER_NAME}" > /dev/null 2>&1; then
  kind create cluster --name "${CLUSTER_NAME}"
fi

helm upgrade --install mimir grafana/mimir-distributed -f "${MIMIR_VALUES}" -n mimir --create-namespace
helm upgrade --install loki grafana/loki -f "${LOKI_VALUES}" -n loki --create-namespace
helm upgrade --install tempo grafana/tempo -f "${TEMPO_VALUES}" -n tempo --create-namespace
helm upgrade --install grafana grafana/grafana -f "${GRAFANA_VALUES}" -n grafana --create-namespace
