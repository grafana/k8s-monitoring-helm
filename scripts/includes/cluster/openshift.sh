#!/usr/bin/env bash

createOpenShiftCluster() {
  local clusterName=$1
  local clusterConfig=$2

  clusterInstallerFilesDir="$(cd "$(dirname "${clusterConfig}")" && pwd)/${clusterName}-installer-files"
  if [ ! -f "${clusterInstallerFilesDir}/auth/kubeconfig" ]; then
    mkdir -p "${clusterInstallerFilesDir}"
    yq ".metadata.name=\"${clusterName}\"" "${clusterConfig}" > "${clusterInstallerFilesDir}/install-config.yaml"
    openshift-install create cluster --dir "${clusterInstallerFilesDir}"
  fi
  ln -sf "${clusterInstallerFilesDir}/auth/kubeconfig" "$(dirname "${clusterConfig}")/kubeconfig.yaml"
}

deleteOpenShiftCluster() {
  local clusterName=$1
  local clusterConfig=$2

  clusterInstallerFilesDir="$(dirname "${clusterConfig}")/${clusterName}-installer-files"
  openshift-install destroy cluster --dir "${clusterInstallerFilesDir}"
}
