#!/usr/bin/env bash
# shellcheck disable=SC2086  # We do a lot of intentional use of unquoted variables.
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/utils.sh"
source "${PARENT_DIR}/scripts/includes/logging.sh"
source "${PARENT_DIR}/scripts/includes/cluster/gke.sh"
source "${PARENT_DIR}/scripts/includes/cluster/kind.sh"

heading "Kubernetes Monitoring Helm" "Integration Tester"

usage() {
  echo "USAGE: run-integration-test.sh <test-dir>"
  echo ""
  echo "Runs an integration test"
  echo ""
  echo "  <test-dir>           - The test directory. Expects this file:"
  echo "    values.yaml        - The values file for the k8s-monitoring Helm chart."
  echo "    deployments        - Manifest files to deploy, including Flux objects."
  echo "    (Optional cluster config files):"
  echo "    kind-cluster-config.yaml          - Config file for creating a Kind cluster."
  echo "    gke-cluster-config.yaml           - Config file for creating a GKE cluster."
  echo "    gke-autopilot-cluster-config.yaml - Config file for creating a GKE Autopilot cluster."
}

CREATE_CLUSTER=${CREATE_CLUSTER:-true}
DELETE_CLUSTER=${DELETE_CLUSTER:-false}
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
  if [ -n "${RANDOM_NUMBER}" ]; then clusterName="${clusterName}-${RANDOM_NUMBER}"; fi
  if [ -f "${TEST_DIRECTORY}/kind-cluster-config.yaml" ]; then
    createKindCluster "${clusterName}" "${TEST_DIRECTORY}/kind-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/gke-cluster-config.yaml" ]; then
    createGKECluster "${clusterName}" "${TEST_DIRECTORY}/gke-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml" ]; then
    createGKEAutopilotCluster "${clusterName}" "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml"
  else
    createKindCluster "${clusterName}"
  fi
fi

deleteCluster() {
  clusterName=$(yq eval '.cluster.name' "${TEST_DIRECTORY}/values.yaml")
  if [ -n "${RANDOM_NUMBER}" ]; then clusterName="${clusterName}-${RANDOM_NUMBER}"; fi
  if [ -f "${TEST_DIRECTORY}/kind-cluster-config.yaml" ]; then
    deleteKindCluster "${clusterName}" "${TEST_DIRECTORY}/kind-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/gke-cluster-config.yaml" ]; then
    deleteGKECluster "${clusterName}" "${TEST_DIRECTORY}/gke-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml" ]; then
    deleteGKECluster "${clusterName}" "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml"
  else
    deleteKindCluster "${clusterName}"
  fi
}
if [ "${DELETE_CLUSTER}" == "true" ]; then
  trap deleteCluster EXIT
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
clusterName=$(yq eval '.cluster.name' "${TEST_DIRECTORY}/values.yaml")
if [ -n "${RANDOM_NUMBER}" ]; then clusterName="${clusterName}-${RANDOM_NUMBER}"; fi
helm upgrade --install k8smon ${PARENT_DIR}/charts/k8s-monitoring -f ${TEST_DIRECTORY}/values.yaml --set "cluster.name=${clusterName}" --wait

# Run tests
helm test k8s-monitoring-test
