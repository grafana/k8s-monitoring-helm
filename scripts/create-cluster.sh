#!/usr/bin/env bash
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/cluster/eks.sh"
source "${PARENT_DIR}/scripts/includes/cluster/gke.sh"
source "${PARENT_DIR}/scripts/includes/cluster/kind.sh"
source "${PARENT_DIR}/scripts/includes/cluster/openshift.sh"

usage() {
  echo "USAGE: create-cluster.sh <test-dir>"
  echo ""
  echo "Creates a real Kubernetes Cluster"
  echo ""
  echo "  <test-dir>           - The test directory. Expects this file:"
  echo "    values.yaml        - The values file for the k8s-monitoring Helm chart."
  echo "    (Optional cluster config files):"
  echo "    kind-cluster-config.yaml          - Config file for creating a Kind cluster."
  echo "    eks-cluster-config.yaml           - Config file for creating an EKS cluster."
  echo "    gke-cluster-config.yaml           - Config file for creating a GKE cluster."
  echo "    gke-autopilot-cluster-config.yaml - Config file for creating a GKE Autopilot cluster."
  echo "    openshift-cluster-config.yaml     - Config file for creating an OpenShift cluster."
}

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

echo "Creating cluster ${clusterName}..."
if [ -f "${TEST_DIRECTORY}/kind-cluster-config.yaml" ]; then
  createKindCluster "${clusterName}" "${TEST_DIRECTORY}/kind-cluster-config.yaml"
elif [ -f "${TEST_DIRECTORY}/eks-cluster-config.yaml" ]; then
  createEKSCluster "${clusterName}" "${TEST_DIRECTORY}/eks-cluster-config.yaml"
elif [ -f "${TEST_DIRECTORY}/gke-cluster-config.yaml" ]; then
  createGKECluster "${clusterName}" "${TEST_DIRECTORY}/gke-cluster-config.yaml"
elif [ -f "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml" ]; then
  createGKEAutopilotCluster "${clusterName}" "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml"
elif [ -f "${TEST_DIRECTORY}/openshift-cluster-config.yaml" ]; then
  createOpenShiftCluster "${clusterName}" "${TEST_DIRECTORY}/openshift-cluster-config.yaml"
else
  createKindCluster "${clusterName}"
fi
