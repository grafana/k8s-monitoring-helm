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
  if ! kind delete cluster --name "${clusterName}"; then
    # Sometimes it just needs a minute and it'll work the second time.
    # This has to do with something related to Beyla being installed and its eBPF hooks into the node.
    sleep 60
    kind delete cluster --name "${clusterName}"
  fi
}
