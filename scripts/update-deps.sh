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

helm repo update

updateDependency() {
  name=$1
  slug=$2
  chartDir=$3
  latestVersion=$(helm search repo ${slug} --output json | jq -r '.[0].version')
  echo "Updating ${name} to ${latestVersion}..."
  pushd ${chartDir}
  yq eval ".dependencies[] |= select(.name == \"${slug}\") .version = \"${latestVersion}\"" -i Chart.yaml
  helm dependency update
  popd
}

# Iterate over the provided dependencies
for dependency in "$@"; do
  # Show usage for -h or --help
  if [[ "$dependency" == "-h" || "$dependency" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ "$dependency" == "alloy" ]]; then
    updateDependency "Grafana Alloy" "alloy" "charts/k8s-monitoring"
    updateDependency "Grafana Alloy" "alloy" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "ksm" ]]; then
    updateDependency "kube-state-metrics" "kube-state-metrics" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "kube-state-metrics" "kube-state-metrics" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "node-exporter" ]]; then
    updateDependency "Node Exporter" "prometheus-node-exporter" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "Node Exporter" "prometheus-node-exporter" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "windows-exporter" ]]; then
    updateDependency "Windows Exporter" "prometheus-windows-exporter" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "Windows Exporter" "prometheus-windows-exporter" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "kepler" ]]; then
    updateDependency "Kepler" "kepler" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "Kepler" "kepler" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "opencost" ]]; then
    updateDependency "OpenCost" "opencost" "charts/k8s-monitoring/charts/feature-cluster-metrics"
    updateDependency "OpenCost" "opencost" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "beyla" ]]; then
    updateDependency "Grafana Beyla" "beyla" "charts/k8s-monitoring/charts/feature-auto-instrumentation"
    updateDependency "Grafana Beyla" "beyla" "charts/k8s-monitoring-v1"
  fi

  if [[ "$dependency" == "prometheus-operator-crds" ]]; then
    updateDependency "Prometheus Operator CRDs" "prometheus-operator-crds" "charts/k8s-monitoring/charts/feature-promtheus-operator-objects"
    updateDependency "Prometheus Operator CRDs" "prometheus-operator-crds" "charts/k8s-monitoring-v1"
  fi

done

echo "Regenerating files..."
make clean build test

echo "Update complete."
