#!/usr/bin/env bash

createAKSCluster() {
  local clusterName=$1
  local clusterConfig=$2

  if ! az aks list --query '[].name' | grep -q "${clusterName}"; then
    args=$(yq eval -r -o=json '[.args | to_entries | .[] | select(.value != null)] | map("--" + .key + "=" + (.value | tostring)) | join(" ")' "${clusterConfig}")
    args=$(yq eval -r -o=json '[.args | to_entries | .[] | select(.value == null)] | map("--" + .key) | join(" ")' "${clusterConfig}")
    bashCommand="az aks create --yes --name \"${clusterName}\" ${args}"
    echo "${bashCommand}"
    eval "${bashCommand}"
  fi
  az aks get-credentials --name "${clusterName}"
}

deleteAKSCluster() {
  local clusterName=$1
  local clusterConfig=$2

  if az aks list --query '[].name' | grep -q "${clusterName}"; then
    bashCommand="az aks delete --yes --name \"${clusterName}\""
    echo "${bashCommand}"
    eval "${bashCommand}"
  fi
}