#!/usr/bin/env bash
# shellcheck disable=SC2086  # We do a lot of intentional use of unquoted variables.
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/utils.sh"
source "${PARENT_DIR}/scripts/includes/logging.sh"
source "${PARENT_DIR}/scripts/includes/cluster/eks.sh"
source "${PARENT_DIR}/scripts/includes/cluster/gke.sh"
source "${PARENT_DIR}/scripts/includes/cluster/kind.sh"

heading "Kubernetes Monitoring Helm" "Cluster Test Runner"

usage() {
  echo "USAGE: run-cluster-test.sh <test-dir>"
  echo ""
  echo "Runs a test against a real Kubernetes Cluster"
  echo ""
  echo "  <test-dir>           - The test directory. Expects this file:"
  echo "    values.yaml        - The values file for the k8s-monitoring Helm chart."
  echo "    deployments        - Manifest files to deploy, including Flux objects."
  echo "    (Optional cluster config files):"
  echo "    kind-cluster-config.yaml          - Config file for creating a Kind cluster."
  echo "    eks-cluster-config.yaml           - Config file for creating an EKS cluster."
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
if [ ! -f "${TEST_DIRECTORY}/values.yaml" ]; then
  echo "Values file (${TEST_DIRECTORY}/values.yaml) not found! This is a required file."
  usage
  exit 1
fi

set -eo pipefail  # Exit immediately if a command fails.

clusterName=$(yq eval '.cluster.name' "${TEST_DIRECTORY}/values.yaml")
if [ -n "${RANDOM_NUMBER}" ]; then clusterName="${clusterName}-${RANDOM_NUMBER}"; fi

#
# Cluster creation
#
if [ "${CREATE_CLUSTER}" == "true" ]; then
  if [ -f "${TEST_DIRECTORY}/kind-cluster-config.yaml" ]; then
    createKindCluster "${clusterName}" "${TEST_DIRECTORY}/kind-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/eks-cluster-config.yaml" ]; then
    createEKSCluster "${clusterName}" "${TEST_DIRECTORY}/eks-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/gke-cluster-config.yaml" ]; then
    createGKECluster "${clusterName}" "${TEST_DIRECTORY}/gke-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml" ]; then
    createGKEAutopilotCluster "${clusterName}" "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml"
  else
    createKindCluster "${clusterName}"
  fi
fi

deleteCluster() {
  if [ -f "${TEST_DIRECTORY}/kind-cluster-config.yaml" ]; then
    deleteKindCluster "${clusterName}" "${TEST_DIRECTORY}/kind-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/eks-cluster-config.yaml" ]; then
    deleteEKSCluster "${clusterName}" "${TEST_DIRECTORY}/eks-cluster-config.yaml"
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

# Apply the deployments directory
if [ -f "${TEST_DIRECTORY}/Makefile" ]; then
  make -C "${TEST_DIRECTORY}" clean all
fi
if [ -d "${TEST_DIRECTORY}/deployments" ]; then
  kubectl apply -f ${TEST_DIRECTORY}/deployments
fi

# Deploy k8s-monitoring
#    OpenCost's defaultClusterId is set to the cluster name always, even if OpenCost is not enabled
echo helm upgrade --install k8smon ${PARENT_DIR}/charts/k8s-monitoring -f ${TEST_DIRECTORY}/values.yaml --set "cluster.name=${clusterName}" --set "clusterMetrics.opencost.opencost.exporter.defaultClusterId=${clusterName}" --wait
helm upgrade --install k8smon ${PARENT_DIR}/charts/k8s-monitoring -f ${TEST_DIRECTORY}/values.yaml --set "cluster.name=${clusterName}" --set "clusterMetrics.opencost.opencost.exporter.defaultClusterId=${clusterName}" --wait

# Ensure that the test chart has been deployed
for i in $(seq 1 60); do
  if helm ls | grep k8s-monitoring-test | grep deployed > /dev/null; then
    break
  fi
  if [ $i -eq 60 ]; then
    echo "k8s-monitoring-test Helm chart failed to deploy"
    exit 1
  fi
  sleep 1
done

# Run tests
echo helm test k8s-monitoring-test --logs
helm test k8s-monitoring-test --logs
