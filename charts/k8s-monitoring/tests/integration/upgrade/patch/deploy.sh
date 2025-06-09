#!/usr/bin/env bash

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "${TEST_DIR}" || exit 1

set -eo pipefail

CLUSTER_NAME=$(yq eval '.cluster.name' values.yaml)
CURRENT_VERSION="$(yq eval '.version' ../../../../Chart.yaml)"
IFS='.' read -r major minor patch <<< "${CURRENT_VERSION}"
if [ "${patch}" -eq 0 ]; then
  echo "Patch version is 0. This test is not applicable."
  exit 1
else
  PREVIOUS_PATCH_RELEASE="${major}.${minor}.$((patch - 1))"
fi

echo "Installing version ${PREVIOUS_PATCH_RELEASE}..."
helm upgrade --install k8smon --version "${PREVIOUS_PATCH_RELEASE}" --repo https://grafana.github.io/helm-charts k8s-monitoring -f "${TEST_DIR}/values.yaml" --set "cluster.name=${CLUSTER_NAME}" --set "clusterMetrics.opencost.opencost.exporter.defaultClusterId=${CLUSTER_NAME}" --wait

echo "Testing and waiting for data from the previous version..."
helm test k8s-monitoring-test --logs

echo "Upgrading to current version (${CURRENT_VERSION})..."
helm upgrade k8smon "${TEST_DIR}/../../../../" -f "${TEST_DIR}/values.yaml" --set "cluster.name=${CLUSTER_NAME}" --set "clusterMetrics.opencost.opencost.exporter.defaultClusterId=${CLUSTER_NAME}" --wait
