#!/bin/bash

VERSION=$1
PLUGIN_VERSION=$2

if [[ -z "${VERSION}" ]] || [[ "${VERSION}" == "-h" ]] || [[ "${VERSION}" == "--help" ]]; then
  echo "set-version.sh <version> [<appVersion>] - Update the chart version and regenerate generated content"
  echo
  echo "  <version> The version number to use for the chart."
  echo "  <appVersion> The app version number to use for the chart (default to latest release)."
fi

if [[ -z "${PLUGIN_VERSION}" ]]; then
  PLUGIN_VERSION=$(gh release list --repo grafana/grafana-k8s-plugin --limit 1 --json name --jq '.[].name')
  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    echo "Failed to get latest Grafana Kubernetes plugin version. This functionality is only available for Grafana Labs employees."
    exit 1
  fi
fi

CHART_FILE=Chart.yaml

yq e ".version = \"${VERSION}\"" "${CHART_FILE}" > "${CHART_FILE}.new" && mv "${CHART_FILE}.new" "${CHART_FILE}"
yq e ".appVersion = \"${PLUGIN_VERSION}\"" "${CHART_FILE}" > "${CHART_FILE}.new" && mv "${CHART_FILE}.new" "${CHART_FILE}"

# shellcheck disable=SC2046 disable=SC2312
NUM_EXAMPLES=$(find docs/examples -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
make -j "${NUM_EXAMPLES}" examples
make README.md docs/RBAC.md values.schema.json
