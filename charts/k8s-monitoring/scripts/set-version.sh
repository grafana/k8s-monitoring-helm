#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CHART_DIR=$(realpath "${SCRIPT_DIR}/..")
VERSION=$1

if [[ -z "${VERSION}" ]] || [[ "${VERSION}" == "-h" ]] || [[ "${VERSION}" == "--help" ]]; then
  echo "set-version.sh <version> - Update the chart version and regenerate generated content"
  echo
  echo "  version - The version number to use for the chart."
  echo "            Use 'major', 'minor', or 'patch' to increment the respective version part."
fi

CHART_FILE="${CHART_DIR}/Chart.yaml"
CHART_NAME=$(yq e '.name' "${CHART_FILE}")

CURRENT_VERSION=$(yq e '.version' "${CHART_FILE}")
IFS='.' read -r major minor patch <<< "${CURRENT_VERSION}"

if [[ "${VERSION}" == "major" ]]; then
  VERSION="$((major + 1)).0.0"
elif [[ "${VERSION}" == "minor" ]]; then
  VERSION="${major}.$((minor + 1)).0"
elif [[ "${VERSION}" == "patch" ]]; then
  VERSION="${major}.${minor}.$((patch + 1))"
fi

set -eo pipefail
echo "Changing ${CHART_NAME} version from ${CURRENT_VERSION} to ${VERSION}..."

yq eval    ".version = \"${VERSION}\"" "${CHART_FILE}" > "${CHART_FILE}.new" && mv "${CHART_FILE}.new" "${CHART_FILE}"
yq eval ".appVersion = \"${VERSION}\"" "${CHART_FILE}" > "${CHART_FILE}.new" && mv "${CHART_FILE}.new" "${CHART_FILE}"

echo "Rebuilding generated content..."
make -C "${CHART_DIR}" clean build test > /dev/null
