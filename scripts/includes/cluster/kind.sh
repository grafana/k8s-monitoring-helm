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
  for attempt in $(seq 1 30); do
    if kind delete cluster --name "${clusterName}"; then
      break
    elif [ "${attempt}" -eq 30 ]; then
      echo "Failed to delete cluster ${clusterName} after 30 attempts."
      exit 1
    fi
    # Sometimes it can take a few attempts.`
    # This has to do with something related to Beyla being installed and its eBPF hooks into the node.
    echo "Attempt ${attempt} to delete cluster ${clusterName} failed. Retrying..."
    sleep 10
  done
}
