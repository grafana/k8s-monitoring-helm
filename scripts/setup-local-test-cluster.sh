#!/bin/bash

CLUSTER_NAME="k8s-mon-test-cluster"
CLUSTER_CONFIG="./.github/configs/cluster-config.yaml"
GRAFANA_ALLOY_VALUES="./.github/configs/alloy-config.yaml"
GRAFANA_ALLOY_LOKI_OTLP_VALUES="./.github/configs/alloy-config-loki-otlp.yaml"
GRAFANA_ALLOY_RECEIVER_SERVICE="./.github/configs/receiver-service.yaml"
PROMETHEUS_VALUES="./.github/configs/prometheus.yaml"
PROMETHEUS_WORKLOAD_VALUES="./.github/configs/prometheus-workload.yaml"
CREDENTIALS="./.github/configs/credentials.yaml"
LOKI_VALUES="./.github/configs/loki.yaml"
LOKI_RULE_OBJECT="./.github/configs/lokiRule.yaml"
#TEMPO_VALUES=""  # No values for now
PYROSCOPE_VALUES="./.github/configs/pyroscope.yaml"
GRAFANA_VALUES="./.github/configs/grafana.yaml"
PODLOGS_OBJECTS="./.github/configs/podlogs.yaml"
MYSQL_VALUES="./.github/configs/mysql.yaml"
MYSQL_CONFIG_MANIFEST="./.github/configs/mysql-config.yaml"
CERT_MANAGER_VALUES="./.github/configs/cert-manager.yaml"
SECRETGEN_CONTROLLER_MANIFEST=https://github.com/carvel-dev/secretgen-controller/releases/latest/download/release.yml
CERTIFICATES_MANIFEST="./.github/configs/certificates.yaml"

K8SMON_CHART_PATH="charts/k8s-monitoring"
K8SMON_VALUES=$1

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
helm upgrade --install mysql oci://registry-1.docker.io/bitnamicharts/mysql -f "${MYSQL_VALUES}" -n mysql --create-namespace --wait
kubectl apply -f "${MYSQL_CONFIG_MANIFEST}"

# Cert Manager for integration testing (service annotations)
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager -f "${CERT_MANAGER_VALUES}" -n cert-manager --create-namespace --wait

# This Alloy instance is only used for generating metrics, logs, and traces that'll get
# sent to the K8s Monitoring Alloy to test ingesting MLT from receivers.
kubectl apply -f "${GRAFANA_ALLOY_RECEIVER_SERVICE}"
helm upgrade --install alloy grafana/alloy -f "${GRAFANA_ALLOY_VALUES}" -n alloy --create-namespace --wait

# This prometheus instance is used pod annotation testing with https
helm upgrade --install prometheus-workload prometheus-community/prometheus -f "${PROMETHEUS_WORKLOAD_VALUES}" -n prometheus --create-namespace --wait

# Deploy the Prometheus Operator CRDs, since we want to deploy Loki with a ServiceMonitor later
helm upgrade --install prom-crds prometheus-community/prometheus-operator-crds --wait

echo "Deploying Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus -f "${PROMETHEUS_VALUES}" -n prometheus --create-namespace --wait

echo "Deploying Loki..."
helm upgrade --install loki grafana/loki -f "${LOKI_VALUES}" -n loki --create-namespace --wait
helm upgrade --install loki-otlp grafana/alloy -f "${GRAFANA_ALLOY_LOKI_OTLP_VALUES}" -n loki --wait
kubectl apply -f "${LOKI_RULE_OBJECT}"

echo "Deploying Tempo..."
helm upgrade --install tempo grafana/tempo -n tempo --create-namespace --wait

echo "Deploying Pyroscope..."
helm upgrade --install pyroscope grafana/pyroscope -f "${PYROSCOPE_VALUES}" -n pyroscope --create-namespace --wait

echo "Deploying Grafana..."
helm upgrade --install grafana grafana/grafana -f "${GRAFANA_VALUES}" -n grafana --create-namespace --wait
kubectl apply -f "${PODLOGS_OBJECTS}"

if [ -n "${K8SMON_VALUES}" ]; then
  helm upgrade --install k8smon "${K8SMON_CHART_PATH}" -f "${K8SMON_VALUES}" -n monitoring --create-namespace --wait
  helm test k8smon -n monitoring
fi
