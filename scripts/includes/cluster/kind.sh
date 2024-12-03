#!/usr/bin/env bash

createKindCluster() {
  local clusterName=$1
  local clusterConfig=$2

  args=""
  if [ -f "${clusterConfig}" ]; then args="--config ${clusterConfig}"; fi
  if ! kind get clusters | grep -q "${clusterName}"; then
    bashCommand="kind create cluster --name \"${clusterName}\" ${args}"
    echo "${bashCommand}"
    eval "${bashCommand}"
  fi
}

deleteKindCluster() {
  local clusterName=$1
  kind delete cluster --name "${clusterName}"
}
