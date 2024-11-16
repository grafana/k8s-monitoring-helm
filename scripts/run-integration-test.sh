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

HEADLESS=${HEADLESS:-false}
TEST_DIRECTORY=$1
if [ -z "${TEST_DIRECTORY}" ]; then
  echo "Test directory not defined!"
  usage
  exit 1
fi

testManifest="${TEST_DIRECTORY}/test-manifest.yaml"
if [ ! -f "${testManifest}" ]; then
  echo "${testManifest} does not exist!"
  usage
  exit 1
fi

set -eo pipefail  # Exit immediately if a command fails.
#
# Cluster creation
#
clusterType=$(yq -r ".cluster.type // \"kind\"" "${testManifest}")
clusterName=$(yq -r ".cluster.name // \"$(basename "${TEST_DIRECTORY}")\"" "${testManifest}")
clusterConfig=$(yq -r ".cluster.config // \"\"" "${testManifest}")

if [ "${clusterType}" == "kind" ]; then
  if ! kind get clusters | grep -q "${clusterName}"; then
    if [ ! -f "${clusterConfig}" ]; then
      kind create cluster --name "${clusterName}"
    else
      kind create cluster --name "${clusterName}" --config "${clusterConfig}"
    fi
  fi
else
  echo "Unknown cluster type: \"${clusterType}\""
fi

#
# Deployments
#
deploymentCount=$(yq -r '.deployments | length' "${testManifest}")
for ((i=0; i<deploymentCount; i++)); do
  name=$(yq -r .deployments[$i].name "${testManifest}")
  type=$(yq -r .deployments[$i].type "${testManifest}")
  skipOnHeadless=$(yq -r ".deployments[$i].type // \"false\"" "${testManifest}")

  if [ "${HEADLESS}" == "true" ] && [ "${skipOnHeadless}" == "true" ]; then
    continue
  fi
  echo "Deploying ${name}..."

  namespace=$(yq -r ".deployments[$i].namespace // \"\"" "${testManifest}")
  if [ -n "${namespace}" ]; then
    namespaceArg="--namespace ${namespace}"
  fi

  if [ "${type}" == "manifest" ]; then
    manifestURL=$(yq -r ".deployments[$i].url // \"\"" "${testManifest}")
    manifestFile=$(yq -r ".deployments[$i].file // \"\"" "${testManifest}")
    if [ -n "${manifestURL}" ]; then
      kubectl apply -f "${manifestURL}" ${namespaceArg}
    elif [ -n "${manifestFile}" ]; then
      envsubst < "${TEST_DIRECTORY}/${manifestFile}" | kubectl apply ${namespaceArg} -f -
    else
      echo "No URL or file specified for manifest prerequisite \"${name}\""
      exit 1
    fi

  elif [ "${type}" == "helm" ]; then
    helmRepo=$(yq -r ".deployments[$i].repo // \"\"" "${testManifest}")
    helmRepoArg=""
    if [ -n "${helmRepo}" ]; then helmRepoArg="--repo ${helmRepo}"; fi
    helmChart=$(yq -r ".deployments[$i].chart // \"\"" "${testManifest}")
    helmChartPath=$(yq -r ".deployments[$i].chartPath // \"\""  "${testManifest}")
    prereqVersion=$(yq -r ".prerequisites[$i].version // \"\"" "${testManifest}")
    prereqVersionArg=""
    if [ -n "${prereqVersion}" ]; then prereqVersionArg="--version ${prereqVersion}"; fi
    helmValues="$(yq -r ".deployments[$i].values // \"\"" "${testManifest}")"
    helmValuesFile="$(yq -r ".deployments[$i].valuesFile // \"\"" "${testManifest}")"
    helmTest="$(yq -r ".deployments[$i].test // \"false\"" "${testManifest}")"

    if [ -n "${helmChartPath}" ]; then
      helmChart="$(cd "$(dirname "${PARENT_DIR}/${helmChartPath}")" && pwd)/$(basename "${helmChartPath}")"
    fi

    if [ -n "${helmValuesFile}" ]; then
      helm upgrade --install "${name}" ${namespaceArg} --create-namespace ${helmRepoArg} "${helmChart}" ${prereqVersionArg} -f "${TEST_DIRECTORY}/${helmValuesFile}" --hide-notes --wait
    elif [ -n "${helmChart}" ]; then
      echo "${helmValues}" > temp-values.yaml
      helm upgrade --install "${name}" ${namespaceArg} --create-namespace ${helmRepoArg} "${helmChart}" ${prereqVersionArg} -f temp-values.yaml --hide-notes --wait
      rm temp-values.yaml
    else
      helm upgrade --install "${name}" ${namespaceArg} --create-namespace --repo "${helmRepo}" "${helmChart}" ${prereqVersionArg} --hide-notes --wait
    fi

    if [ "${helmTest}" == "true" ]; then
      helm test "${name}" ${namespaceArg} --logs
    fi
  else
    echo "Unknown deployment type: ${type}"
    exit 1
  fi
done
