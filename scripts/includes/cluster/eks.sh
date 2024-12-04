#!/usr/bin/env bash

createEKSCluster() {
  local clusterName=$1
  local clusterConfig=$2

  if ! eksctl get cluster --name "${clusterName}" 2>/dev/null ; then \
    echo eksctl create cluster --config-file <(yq eval ".metadata.name=\"${clusterName}\"" "${clusterConfig}")
    eksctl create cluster --config-file <(yq eval ".metadata.name=\"${clusterName}\"" "${clusterConfig}")
  fi
}

deleteEKSCluster() {
  if eksctl get cluster --name "${clusterName}" 2>/dev/null ; then \
    echo eksctl delete cluster --name "${clusterName}"
    eksctl delete cluster --name "${clusterName}"
  fi
}
