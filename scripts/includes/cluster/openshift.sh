#!/usr/bin/env bash

createOpenShiftCluster() {
  local clusterName=$1
  local clusterConfig=$2

  clusterInstallerFilesDir="$(dirname "${clusterConfig}")/${clusterName}-installer-files"
  mkdir -p "${clusterInstallerFilesDir}"
  yq ".metadata.name=\"${clusterName}\"" "${clusterConfig}" > "${clusterInstallerFilesDir}/install-config.yaml"
  openshift-install create cluster --dir "${clusterInstallerFilesDir}"
  ln -s "${clusterInstallerFilesDir}/auth/kubeconfig" "$(dirname "${clusterConfig}")/kubeconfig.yaml"
}

deleteOpenShiftCluster() {
  local clusterName=$1
  local clusterConfig=$2

  clusterInstallerFilesDir="$(dirname "${clusterConfig}")/${clusterName}-installer-files"
  openshift-install destroy cluster --dir "${clusterInstallerFilesDir}"
}
