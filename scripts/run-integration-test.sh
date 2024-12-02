#!/usr/bin/env bash
# shellcheck disable=SC2086  # We do a lot of intentional use of unquoted variables.
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/utils.sh"
source "${PARENT_DIR}/scripts/includes/logging.sh"

heading "Kubernetes Monitoring Helm" "Integration Tester"

usage() {
  echo "USAGE: run-integration-test.sh <test-dir>"
  echo ""
  echo "Runs an integration test"
  echo ""
  echo "  <test-dir>           - The test directory. Expects this file:"
  echo "    test-manifest.yaml - The test manifest, which defines cluster, and deployments"
}

CREATE_CLUSTER=${CREATE_CLUSTER:-true}
HEADLESS=${HEADLESS:-false}
TEST_DIRECTORY=$1
if [ -z "${TEST_DIRECTORY}" ]; then
  echo "Test directory not defined!"
  usage
  exit 1
fi

set -eo pipefail  # Exit immediately if a command fails.

#
# Cluster creation
#
if [ "${CREATE_CLUSTER}" == "true" ]; then
  clusterName=$(yq eval '.cluster.name' "${TEST_DIRECTORY}/values.yaml")
  if [ -f "${TEST_DIRECTORY}/kind-cluster-config.yaml" ]; then
    if ! kind get clusters | grep -q "${clusterName}"; then
      kind create cluster --name "${clusterName}" --config "${TEST_DIRECTORY}/kind-cluster-config.yaml"
    fi
  elif [ -f "${TEST_DIRECTORY}/gke-cluster-config.yaml" ]; then
    clusterType="gke"
    clusterConfig="${TEST_DIRECTORY}/gke-cluster-config.yaml"
    echo "gcloud cluster creation not yet implemented"
  else
    if ! kind get clusters | grep -q "${clusterName}"; then
      kind create cluster --name "${clusterName}"
    fi
  fi
fi

# Deploy flux
if command -v flux &> /dev/null; then
  flux install
else
  helm upgrade --install --namespace flux-system --create-namespace flux oci://ghcr.io/fluxcd-community/charts/flux2 --wait
fi

# Deploy prerequisites
kubectl apply -f ${TEST_DIRECTORY}/deployments

# Deploy k8s-monitoring
helm upgrade --install k8smon ${PARENT_DIR}/charts/k8s-monitoring -f ${TEST_DIRECTORY}/values.yaml --wait

# Run tests
helm test k8s-monitoring-test
