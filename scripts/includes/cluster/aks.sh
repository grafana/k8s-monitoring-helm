#!/usr/bin/env bash

createAKSCluster() {
  local clusterName=$1
  local clusterConfig=$2

  if ! az does cluster exist; then
    echo az create cluster "${clusterName}" --config "${clusterConfig}"...
    az create cluster "${clusterName}" --config "${clusterConfig}"...
  fi
}

deleteAKSCluster() {
  local clusterName=$1
  if az does cluster exist; then
    echo az delete cluster "${clusterName}" ...
    az delete cluster "${clusterName}" ...
  fi
}
