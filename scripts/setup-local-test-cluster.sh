#!/bin/bash

CLUSTER_NAME="k8s-mon-test-cluster"
CLUSTER_CONFIG="./.github/configs/cluster-config.yaml"
PROMETHEUS_VALUES="./.github/configs/prometheus.yaml"
CREDENTIALS="./.github/configs/credentials.yaml"
LOKI_VALUES="./.github/configs/loki.yaml"
GRAFANA_VALUES="./.github/configs/grafana.yaml"
SECRETGEN_CONTROLLER_MANIFEST=https://github.com/carvel-dev/secretgen-controller/releases/latest/download/release.yml
CERTIFICATES_MANIFEST="./.github/configs/certificates.yaml"

if ! kind get nodes --name "${CLUSTER_NAME}" | grep "No kind nodes found for cluster \"${CLUSTER_NAME}\"" > /dev/null 2>&1; then
  echo "Creating cluster..."
  kind create cluster --config "${CLUSTER_CONFIG}" --name "${CLUSTER_NAME}"
fi

set -e

echo "Creating SSL Certs and secrets..."
kubectl apply -f "${SECRETGEN_CONTROLLER_MANIFEST}"
kubectl apply -f "${CERTIFICATES_MANIFEST}"
kubectl apply -f "${CREDENTIALS}"

echo "Deploying Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus -f "${PROMETHEUS_VALUES}" -n prometheus --create-namespace --wait

echo "Deploying Loki..."
helm upgrade --install loki grafana/loki -f "${LOKI_VALUES}" -n loki --create-namespace --wait

echo "Deploying Tempo..."
helm upgrade --install tempo grafana/tempo -n tempo --create-namespace --wait

echo "Deploying Grafana..."
helm upgrade --install grafana grafana/grafana -f "${GRAFANA_VALUES}" -n grafana --create-namespace --wait