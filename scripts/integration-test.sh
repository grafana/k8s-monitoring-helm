#!/usr/bin/env bash
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/utils.sh"
source "${PARENT_DIR}/scripts/includes/logging.sh"

# output the heading
heading "Kubernetes Monitoring Helm" "Integration Tester"

usage() {
  echo "USAGE: integration-test.sh <test-dir>"
  echo ""
  echo "Runs an integration test"
  echo ""
  echo "  <test-dir>           - The test directory. Expects these files:"
  echo "    cluster.yaml       - The Kind cluster config"
  echo "    test-manifest.yaml - The test manifest, which defines test prerequisites"
  echo "    values.yaml        - The k8s-monitoring Helm chart values file to use"
  echo "    test-values.yaml   - The k8s-monitoring-test Helm chart values file to use, which defines test queries"
}

TEST_DIRECTORY=$1
if [ -z "${TEST_DIRECTORY}" ]; then
  echo "Test directory not defined!"
  usage
  exit 1
fi

clusterConfig="${TEST_DIRECTORY}/cluster.yaml"
testManifest="${TEST_DIRECTORY}/test-manifest.yaml"
valuesFile="${TEST_DIRECTORY}/values.yaml"
testValuesFile="${TEST_DIRECTORY}/test-values.yaml"

if [ ! -f "${testManifest}" ]; then
  echo "${testManifest} does not exist!"
  usage
  exit 1
fi

if [ ! -f "${valuesFile}" ]; then
  echo "${valuesFile} does not exist!"
  usage
  exit 1
fi


set -eo pipefail  # Exit immediately if a command fails.

clusterName=$(yq -r .cluster.name "${valuesFile}")

DELETE_CLUSTER=${DELETE_CLUSTER:-true}
DEPLOY_CLUSTER=${DEPLOY_CLUSTER:-true}
cleanup() {
  if [ "${DEPLOY_CLUSTER}" == "true" ] && [ "${DELETE_CLUSTER}" == "true" ]; then
    kind delete cluster --name "${clusterName}" || true
  fi
}
trap cleanup EXIT

if [ "${DEPLOY_CLUSTER}" == "true" ]; then
  echo "Creating cluster..."
  if [ ! -f "${clusterConfig}" ]; then
    kind create cluster --name "${clusterName}"
  else
    kind create cluster --name "${clusterName}" --config "${clusterConfig}"
  fi
fi

echo "Deploying prerequisites..."
prerequisiteCount=$(yq -r '.prerequisites | length' "${testManifest}")
for ((i=0; i<prerequisiteCount; i++)); do
  prerequisiteType=$(yq -r .prerequisites[$i].type "${testManifest}")
  namespace=$(yq -r .prerequisites[$i].namespace "${testManifest}")
  if [ "${prerequisiteType}" == "helm" ]; then
    prereqName=$(yq -r .prerequisites[$i].name "${testManifest}")
    prereqChart=$(yq -r .prerequisites[$i].chart "${testManifest}")
    prereqValuesFile="${PARENT_DIR}/$(yq -r .prerequisites[$i].valuesFile "${testManifest}")"

    if [ -z "${prereqValuesFile}" ]; then
      helm upgrade --install "${prereqName}" --namespace "${namespace}" --create-namespace "${prereqChart}" --hide-notes --wait
    else
      helm upgrade --install "${prereqName}" --namespace "${namespace}" --create-namespace "${prereqChart}" -f "${prereqValuesFile}" --hide-notes --wait
    fi
  fi
done

echo "Deploying chart..."
helm upgrade --install k8smon "${PARENT_DIR}/charts/k8s-monitoring" -f "${valuesFile}" --wait

if [ -f "${testValuesFile}" ]; then
  echo "Deploying test chart..."
  helm upgrade --install k8smon-test "${PARENT_DIR}/charts/k8s-monitoring-test" -f "${testValuesFile}" --wait
  helm test k8smon-test --logs
fi
