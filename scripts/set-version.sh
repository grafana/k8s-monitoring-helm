#!/bin/bash

VERSION=$1
PLUGIN_VERSION=$2

if [ -z "${VERSION}" ] || [ "${VERSION}" == "-h" ] || [ "${VERSION}" == "--help" ]; then
  echo "set-version.sh <version> [<appVersion>] - Update the chart version and regenerate generated content"
  echo
  echo "  <version> The version number to use for the chart."
  echo "  <appVersion> The app version number to use for the chart (default to latest release)."
fi

if [ -z "${PLUGIN_VERSION}" ]; then
  PLUGIN_VERSION=$(gh release list --repo grafana/grafana-k8s-plugin --limit 1 --json name --jq '.[].name')
  if [ $? -ne 0 ]; then
    echo "Failed to get latest Grafana Kubernetes plugin version. This functionality is only available for Grafana Labs employees."
    exit 1
  fi
fi

CHART_FILE=charts/k8s-monitoring/Chart.yaml

yq e ".version = \"${VERSION}\"" "${CHART_FILE}" > "${CHART_FILE}.new" && mv "${CHART_FILE}.new" "${CHART_FILE}"
yq e ".appVersion = \"${PLUGIN_VERSION}\"" "${CHART_FILE}" > "${CHART_FILE}.new" && mv "${CHART_FILE}.new" "${CHART_FILE}"

NUM_EXAMPLES=$(find examples -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
make -j "${NUM_EXAMPLES}" generate-example-outputs
make --directory charts/k8s-monitoring README.md docs/RBAC.md values.schema.json
