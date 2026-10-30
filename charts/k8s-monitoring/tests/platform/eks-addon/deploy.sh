#!/usr/bin/env bash

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "${TEST_DIR}" || exit 1

CLUSTER_NAME="$(yq eval '.cluster.name' "values.yaml")-${RANDOM_NUMBER}"
CLUSTER_REGION=$(yq eval '.metadata.region' eks-cluster-config.yaml)
ADDON_NAME=grafana-labs_kubernetes-monitoring

# Check if the addon already exists
if aws eks list-addons --cluster-name "${CLUSTER_NAME}" --region "${CLUSTER_REGION}" | jq -e ".addons | index(\"${ADDON_NAME}\")" > /dev/null; then
  echo "Updating addon, \"${ADDON_NAME}\" in cluster ${CLUSTER_NAME}..."
  aws eks update-addon \
    --cluster-name "${CLUSTER_NAME}" \
    --region "${CLUSTER_REGION}" \
    --addon-name "${ADDON_NAME}" \
    --configuration-values "$(jq --compact-output . values.json)"
else
  echo "installing addon, \"${ADDON_NAME}\" in cluster ${CLUSTER_NAME}..."
  aws eks create-addon \
    --cluster-name "${CLUSTER_NAME}" \
    --region "${CLUSTER_REGION}" \
    --addon-name "${ADDON_NAME}" \
    --configuration-values "$(jq --compact-output . values.json)"
fi
