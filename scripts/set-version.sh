#!/bin/bash

VERSION=$1

if [ -z "${VERSION}" ] || [ "${VERSION}" == "-h" ] || [ "${VERSION}" == "--help" ]; then
  echo "set-version.sh <version> [<appVersion>] - Update the chart version and regenerate generated content"
  echo
  echo "  <version> The version number to use for the chart."
  echo "  <appVersion> The app version number to use for the chart (default to latest release)."
fi

PLUGIN_VERSION=$(gh release list --repo grafana/grafana-k8s-plugin --limit 1 --json name --jq '.[].name')

CHART_FILE=charts/k8s-monitoring/Chart.yaml

yq e ".version = \"${VERSION}\"" "${CHART_FILE}" > "${CHART_FILE}.new" && mv "${CHART_FILE}.new" "${CHART_FILE}"
yq e ".appVersion = \"${PLUGIN_VERSION}\"" "${CHART_FILE}" > "${CHART_FILE}.new" && mv "${CHART_FILE}.new" "${CHART_FILE}"

helm-docs
make regenerate-example-outputs
make --directory charts/k8s-monitoring README.md docs/RBAC.md values.schema.json
