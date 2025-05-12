#!/usr/bin/env bash

createEKSCluster() {
  local clusterName=$1
  local clusterConfig=$2

  if ! eksctl get cluster --name "${clusterName}" 2>/dev/null ; then
    echo eksctl create cluster --config-file <(yq eval ".metadata.name=\"${clusterName}\"" "${clusterConfig}")
    eksctl create cluster --config-file <(yq eval ".metadata.name=\"${clusterName}\"" "${clusterConfig}")
  fi
}

deleteEKSCluster() {
  local clusterName=$1
  if eksctl get cluster --name "${clusterName}" 2>/dev/null ; then
    # The `--disable-nodegroup-eviction` flag is used to prevent hanging on an unevictable pod when using nodegroups.
    # See https://github.com/eksctl-io/eksctl/issues/6287#issuecomment-1429179939 for more information.
    echo eksctl delete cluster --name "${clusterName}" --disable-nodegroup-eviction
    eksctl delete cluster --name "${clusterName}" --disable-nodegroup-eviction
  fi
}
