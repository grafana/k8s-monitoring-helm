#!/usr/bin/env bash

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "${TEST_DIR}" || exit 1

set -eo pipefail

CLUSTER_NAME=$(yq eval '.cluster.name' values.yaml)
CURRENT_VERSION="$(yq eval '.version' ../../../../Chart.yaml)"
IFS='.' read -r major minor patch <<< "${CURRENT_VERSION}"
PREVIOUS_MAJOR_RELEASE="$((major - 1))"

echo "Installing version ${PREVIOUS_MAJOR_RELEASE}..."
helm upgrade --install k8smon --version "${PREVIOUS_MAJOR_RELEASE}" --repo https://grafana.github.io/helm-charts k8s-monitoring -f "${TEST_DIR}/values.yaml" --set "cluster.name=${CLUSTER_NAME}" --set "clusterMetrics.opencost.opencost.exporter.defaultClusterId=${CLUSTER_NAME}" --wait

echo "Testing and waiting for data from the previous version..."
helm test k8s-monitoring-test --logs

echo "Installing Alloy CRD..."
kubectl apply -f "${TEST_DIR}/collectors.grafana.com_alloy.yaml"

echo "Upgrading to current version (${CURRENT_VERSION})..."
helm upgrade k8smon "${TEST_DIR}/../../../../" -f "${TEST_DIR}/values.yaml" --set "cluster.name=${CLUSTER_NAME}" --set "clusterMetrics.opencost.opencost.exporter.defaultClusterId=${CLUSTER_NAME}" --wait
