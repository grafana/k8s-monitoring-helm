#!/usr/bin/env bash

# Function to display help
function usage() {
  echo "Usage: $0 <dependency1> <dependency2> ..."
  echo "Updates these 3rd party dependencies and regenerates files."
}

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

set -euo pipefail

echo "Updating Helm repositories..."
helm repo update > /dev/null

updateDependency() {
  chart=$1
  slug=$(echo "${chart}" | cut -d'/' -f2)
  chartDir=$2
  chartName=$(basename "${chartDir}")
  latestVersion=$(helm show chart "${chart}" | yq .version)
  echo "Updating ${slug} in ${chartName} to ${latestVersion}..."
  pushd "${chartDir}" || exit 1
  yq eval ".dependencies[] |= select(.name == \"${slug}\") .version = \"${latestVersion}\"" -i Chart.yaml
  echo "Rebuilding dependencies for ${chartName}..."
  helm dependency update > /dev/null
  popd || exit 1
}

# Iterate over the provided dependencies
for dependency in "$@"; do
  # Show usage for -h or --help
  if [[ "$dependency" == "-h" || "$dependency" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ "$dependency" == "alloy" ]]; then
    updateDependency "grafana/alloy" "charts/k8s-monitoring"
    updateDependency "grafana/alloy" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "ksm" ]]; then
    updateDependency "prometheus-community/kube-state-metrics" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "prometheus-community/kube-state-metrics" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "node-exporter" ]]; then
    updateDependency "prometheus-community/prometheus-node-exporter" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "prometheus-community/prometheus-node-exporter" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "windows-exporter" ]]; then
    updateDependency "prometheus-community/prometheus-windows-exporter" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "prometheus-community/prometheus-windows-exporter" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "kepler" ]]; then
    updateDependency "kepler/kepler" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "kepler/kepler" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "opencost" ]]; then
    updateDependency "opencost/opencost" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "opencost/opencost" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "beyla" ]]; then
    updateDependency "grafana/beyla" "charts/k8s-monitoring/charts/feature-auto-instrumentation"
    updateDependency "grafana/beyla" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "prometheus-operator-crds" ]]; then
    updateDependency "prometheus-operator-crds" "charts/k8s-monitoring/charts/feature-promtheus-operator-objects"
    updateDependency "prometheus-operator-crds" "charts/k8s-monitoring-v1"
  fi

done

echo "Regenerating files..."
make clean build test

echo "Update complete."
