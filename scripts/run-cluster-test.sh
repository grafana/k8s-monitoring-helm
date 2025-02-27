#!/usr/bin/env bash
# shellcheck disable=SC2086  # We do a lot of intentional use of unquoted variables.
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/utils.sh"
source "${PARENT_DIR}/scripts/includes/logging.sh"
source "${PARENT_DIR}/scripts/includes/cluster/aks.sh"
source "${PARENT_DIR}/scripts/includes/cluster/eks.sh"
source "${PARENT_DIR}/scripts/includes/cluster/gke.sh"
source "${PARENT_DIR}/scripts/includes/cluster/kind.sh"
source "${PARENT_DIR}/scripts/includes/cluster/openshift.sh"

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
  echo "    openshift-cluster-config.yaml     - Config file for creating an OpenShift cluster."
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
  elif [ -f "${TEST_DIRECTORY}/aks-cluster-config.yaml" ]; then
    createAKSCluster "${clusterName}" "${TEST_DIRECTORY}/aks-cluster-config.yaml"
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
fi

deleteCluster() {
  if [ -f "${TEST_DIRECTORY}/kind-cluster-config.yaml" ]; then
    deleteKindCluster "${clusterName}" "${TEST_DIRECTORY}/kind-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/aks-cluster-config.yaml" ]; then
    deleteAKSCluster "${clusterName}" "${TEST_DIRECTORY}/aks-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/eks-cluster-config.yaml" ]; then
    deleteEKSCluster "${clusterName}" "${TEST_DIRECTORY}/eks-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/gke-cluster-config.yaml" ]; then
    deleteGKECluster "${clusterName}" "${TEST_DIRECTORY}/gke-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml" ]; then
    deleteGKECluster "${clusterName}" "${TEST_DIRECTORY}/gke-autopilot-cluster-config.yaml"
  elif [ -f "${TEST_DIRECTORY}/openshift-cluster-config.yaml" ]; then
    deleteOpenShiftCluster "${clusterName}" "${TEST_DIRECTORY}/openshift-cluster-config.yaml"
  else
    deleteKindCluster "${clusterName}"
  fi
}
if [ "${DELETE_CLUSTER}" == "true" ]; then
  trap deleteCluster EXIT
fi

# If cluster creation left a kubeconfig file, use it
if [ -f "${TEST_DIRECTORY}/kubeconfig.yaml" ]; then
  echo "Using local kubeconfig file: ${TEST_DIRECTORY}/kubeconfig.yaml"
  export KUBECONFIG="${TEST_DIRECTORY}/kubeconfig.yaml"
fi

# Test the cluster connection
kubectl get nodes

# Build any pre-requisite files
if [ -f "${TEST_DIRECTORY}/Makefile" ]; then
  make -C "${TEST_DIRECTORY}" clean all
fi

# Deploy flux
if [ -f "${TEST_DIRECTORY}/flux-manifest.yaml" ]; then
  # Use the locally defined flux-manifest.yaml file, which may include platform specific customizations
  echo "Deploying Flux via ${TEST_DIRECTORY}/flux-manifest.yaml"
  kubectl apply -f "${TEST_DIRECTORY}/flux-manifest.yaml"
elif command -v flux &> /dev/null; then
  # Install via the flux CLI, if it's available
  echo "Deploying Flux via the flux CLI"
  flux install --components=source-controller,helm-controller
else
  # Install via Helm, if the flux CLI is not available
  echo "Deploying Flux via Helm"
  helm upgrade --install --namespace flux-system --create-namespace flux oci://ghcr.io/fluxcd-community/charts/flux2 --wait
fi

# Apply the deployments directory
if [ -d "${TEST_DIRECTORY}/deployments" ]; then
  echo "Applying ${TEST_DIRECTORY}/deployments"
  kubectl apply -f ${TEST_DIRECTORY}/deployments
fi

# Ensure that the test chart has been deployed
FIVE_MINUTES=300
echo "Waiting for k8s-monitoring-test Helm chart to be ready"
for i in $(seq 1 ${FIVE_MINUTES}); do
  if helm status k8s-monitoring-test 2>&1 | grep "STATUS: deployed" > /dev/null ; then
    break
  fi
  if [ $i -eq ${FIVE_MINUTES} ]; then
    echo "k8s-monitoring-test Helm chart failed to deploy"
    helm status k8s-monitoring-test
    flux events --for HelmRelease/k8s-monitoring-test --namespace default
    exit 1
  fi
  sleep 1
done

# Deploy k8s-monitoring
#    OpenCost's defaultClusterId is set to the cluster name always, even if OpenCost is not enabled
if [ -f "${TEST_DIRECTORY}/deploy.sh" ]; then
  echo "Running ${TEST_DIRECTORY}/deploy.sh"
  ${TEST_DIRECTORY}/deploy.sh
else
  echo helm upgrade --install k8smon ${PARENT_DIR}/charts/k8s-monitoring -f ${TEST_DIRECTORY}/values.yaml --set "cluster.name=${clusterName}" --set "clusterMetrics.opencost.opencost.exporter.defaultClusterId=${clusterName}" --wait
  helm upgrade --install k8smon ${PARENT_DIR}/charts/k8s-monitoring -f ${TEST_DIRECTORY}/values.yaml --set "cluster.name=${clusterName}" --set "clusterMetrics.opencost.opencost.exporter.defaultClusterId=${clusterName}" --wait
fi

# Run tests
echo helm test k8s-monitoring-test --logs
helm test k8s-monitoring-test --logs
