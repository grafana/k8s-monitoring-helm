#!/usr/bin/env bash

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="${TEST_DIR}/../../../"
pushd "${TEST_DIR}" || exit 1

set -eo pipefail

echo "Installing tester chart..."
helm upgrade --install tester "${CHART_DIR}" -f "${TEST_DIR}/values-tester.yaml" --namespace monitoring --create-namespace --wait

echo "Installing chart under test..."
helm upgrade --install k8smon "${CHART_DIR}" -f "${TEST_DIR}/values.yaml" --namespace test --create-namespace --wait

sleep 10

echo "Uninstalling chart under test..."
#helm uninstall k8smon --namespace test

echo "Testing and waiting for data from the previous version..."
helm test k8s-monitoring-test --logs
