#!/usr/bin/env bash

# Updates the `image.tag` in the `windows` collector preset to the Windows Server Core (HostProcess) build of the
# Alloy binary version bundled with the current alloy-operator dependency.
#
# The Alloy binary version is not readable from the chart at Helm template time (the operator resolves it at runtime),
# so the `windows` preset pins it. This keeps that pin in sync: it resolves the alloy-operator version from Chart.yaml,
# reads the Alloy Helm chart version that operator deploys (the operator's appVersion), then looks up that chart's
# appVersion (the Alloy binary version) from the grafana/alloy Helm repository index. The resulting tag is
# `<alloy binary version>-windowsservercore-ltsc2022`.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CHART_DIR=$(realpath "${SCRIPT_DIR}/..")

WINDOWS_SUFFIX="windowsservercore-ltsc2022"
PRESET_FILE="${CHART_DIR}/collectors/presets/windows.yaml"

# The alloy-operator version bundled by this chart
ao_version=$(yq '.dependencies[] | select(.name == "alloy-operator") | .version' "${CHART_DIR}/Chart.yaml")
tgz="${CHART_DIR}/charts/alloy-operator-${ao_version}.tgz"
if [[ ! -f "${tgz}" ]]; then
    echo "ERROR: alloy-operator chart not found at ${tgz}. Run 'make build' to fetch dependencies." >&2
    exit 1
fi

# The Alloy Helm chart version that operator deploys is the operator's appVersion
alloy_chart_version=$(tar -xzOf "${tgz}" alloy-operator/Chart.yaml | yq '.appVersion')

# The Alloy binary version is the grafana/alloy Helm chart's appVersion for that chart version
INDEX_FILE=$(mktemp)
trap 'rm -f "${INDEX_FILE}"' EXIT
curl -sf https://grafana.github.io/helm-charts/index.yaml > "${INDEX_FILE}"
alloy_binary=$(yq ".entries.alloy[] | select(.version == \"${alloy_chart_version}\") | .appVersion" "${INDEX_FILE}" | head -1)

if [[ -z "${alloy_binary}" || "${alloy_binary}" == "null" ]]; then
    echo "ERROR: could not resolve the Alloy binary version for alloy chart ${alloy_chart_version}" >&2
    exit 1
fi

tag="${alloy_binary}-${WINDOWS_SUFFIX}"

# Replace only the Windows image tag line, preserving the preset's comments and other keys.
sed -i.bak -E "s|^([[:space:]]*tag:[[:space:]]*).*${WINDOWS_SUFFIX}.*$|\1${tag}|" "${PRESET_FILE}"
rm -f "${PRESET_FILE}.bak"

echo "Set windows preset image.tag to ${tag}"
