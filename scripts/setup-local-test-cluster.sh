#!/bin/bash

CLUSTER_NAME="k8s-mon-test-cluster"
CLUSTER_CONFIG="./.github/configs/cluster-config.yaml"
GRAFANA_AGENT_VALUES="./.github/configs/agent-config.yaml"
GRAFANA_AGENT_RECEIVER_SERVICE="./.github/configs/receiver-service.yaml"
PROMETHEUS_VALUES="./.github/configs/prometheus.yaml"
PROMETHEUS_WORKLOAD_VALUES="./.github/configs/prometheus-workload.yaml"
CREDENTIALS="./.github/configs/credentials.yaml"
LOKI_VALUES="./.github/configs/loki.yaml"
#TEMPO_VALUES=""  # No values for now
GRAFANA_VALUES="./.github/configs/grafana.yaml"
MYSQL_VALUES="./.github/configs/mysql.yaml"
MYSQL_CONFIG_MANIFEST="./.github/configs/mysql-config.yaml"
CERT_MANAGER_VALUES="./.github/configs/cert-manager.yaml"
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

# MySQL for integration testing
helm install mysql oci://registry-1.docker.io/bitnamicharts/mysql -f "${MYSQL_VALUES}" -n mysql --create-namespace --wait
kubectl apply -f "${MYSQL_CONFIG_MANIFEST}"

# Cert Manager for integration testing (service annotations)
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager -f "${CERT_MANAGER_VALUES}" -n cert-manager --create-namespace --wait

# This agent is only used for generating metrics, logs, and traces that'll get
# sent to the K8s Monitoring Grafana Agent to test ingesting MLT from receivers.
kubectl apply -f "${GRAFANA_AGENT_RECEIVER_SERVICE}"
helm install agent grafana/grafana-agent -f "${GRAFANA_AGENT_VALUES}" -n agent --create-namespace --wait

# This prometheus instance is used pod annotation testing with https
helm install prometheus-workload prometheus-community/prometheus -f "${PROMETHEUS_WORKLOAD_VALUES}" -n prometheus --create-namespace --wait

# Deploy the Prometheus Operator CRDs, since we want to deploy Loki with a ServiceMonitor later
helm install prom-crds prometheus-community/prometheus-operator-crds --wait

echo "Deploying Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus -f "${PROMETHEUS_VALUES}" -n prometheus --create-namespace --wait

echo "Deploying Loki..."
helm upgrade --install loki grafana/loki -f "${LOKI_VALUES}" -n loki --create-namespace --wait

echo "Deploying Tempo..."
helm upgrade --install tempo grafana/tempo -n tempo --create-namespace --wait

echo "Deploying Grafana..."
helm upgrade --install grafana grafana/grafana -f "${GRAFANA_VALUES}" -n grafana --create-namespace --wait