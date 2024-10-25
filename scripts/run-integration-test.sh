#!/usr/bin/env bash
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/utils.sh"
source "${PARENT_DIR}/scripts/includes/logging.sh"

heading "Kubernetes Monitoring Helm" "Integration Tester"

usage() {
  echo "USAGE: run-integration-test.sh <test-dir>"
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

DEPLOY_GRAFANA=${DEPLOY_GRAFANA:-true}
DELETE_CLUSTER=${DELETE_CLUSTER:-true}
CREATE_CLUSTER=${CREATE_CLUSTER:-true}
cleanup() {
  helm ls -A || true

  if [ "${CREATE_CLUSTER}" == "true" ] && [ "${DELETE_CLUSTER}" == "true" ]; then
    kind delete cluster --name "${clusterName}" || true
  fi
}
trap cleanup EXIT

if [ "${CREATE_CLUSTER}" == "true" ]; then
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
  prereqName=$(yq -r .prerequisites[$i].name "${testManifest}")
  if [ "${prereqName}" == "grafana" ] && [ "${DEPLOY_GRAFANA}" == "false" ]; then
    continue
  fi

  prereqType=$(yq -r .prerequisites[$i].type "${testManifest}")
  namespace=$(yq -r ".prerequisites[$i].namespace // \"\"" "${testManifest}")
  if [ -n "${namespace}" ]; then
    namespaceArg="--namespace ${namespace}"
  fi

  if [ "${prereqType}" == "manifest" ]; then
    prereqUrl=$(yq -r ".prerequisites[$i].url // \"\"" "${testManifest}")
    prereqFile=$(yq -r ".prerequisites[$i].file // \"\"" "${testManifest}")
    if [ -n "${prereqUrl}" ]; then
      kubectl apply -f "${prereqUrl}" ${namespaceArg}
    elif [ -n "${prereqFile}" ]; then
      envsubst < "${PARENT_DIR}/${prereqFile}" | kubectl apply ${namespaceArg} -f -
    else
      echo "No URL or file specified for manifest prerequisite"
      exit 1
    fi
  elif [ "${prereqType}" == "helm" ]; then
    prereqRepo=$(yq -r ".prerequisites[$i].repo // \"\"" "${testManifest}")
    prereqRepoArg=""
    if [ -n "${prereqRepo}" ]; then prereqRepoArg="--repo ${prereqRepo}"; fi
    prereqChart=$(yq -r .prerequisites[$i].chart "${testManifest}")
    prereqValues="$(yq -r ".prerequisites[$i].values // \"\"" "${testManifest}")"
    prereqValuesFile="$(yq -r ".prerequisites[$i].valuesFile // \"\"" "${testManifest}")"

    if [ -n "${prereqValuesFile}" ]; then
      helm upgrade --install "${prereqName}" ${namespaceArg} --create-namespace ${prereqRepoArg} "${prereqChart}" -f "${PARENT_DIR}/${prereqValuesFile}" --hide-notes --wait
    elif [ -n "${prereqChart}" ]; then
      echo "${prereqValues}" > temp-values.yaml
      helm upgrade --install "${prereqName}" ${namespaceArg} --create-namespace ${prereqRepoArg} "${prereqChart}" -f temp-values.yaml --hide-notes --wait
      rm temp-values.yaml
    else
      helm upgrade --install "${prereqName}" ${namespaceArg} --create-namespace --repo "${prereqRepo}" "${prereqChart}" --hide-notes --wait
    fi
  else
    echo "Unknown prerequisite type: ${prereqType}"
    exit 1
  fi
done

echo "Deploying chart..."
helm upgrade --install k8smon "${PARENT_DIR}/charts/k8s-monitoring" -f "${valuesFile}" --wait

if [ -f "${testValuesFile}" ]; then
  echo "Deploying test chart..."
  helm upgrade --install k8smon-test "${PARENT_DIR}/charts/k8s-monitoring-test" -f <(envsubst < "${testValuesFile}") --wait
  helm test k8smon-test --logs
fi
