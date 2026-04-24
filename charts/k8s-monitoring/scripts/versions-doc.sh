#!/usr/bin/env bash

# Generates docs/Versions.md by scanning git tags for all k8s-monitoring 3.x/4.x releases
# and looking up the bundled Alloy Operator, Alloy chart, and Alloy binary versions.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CHART_DIR=$(realpath "${SCRIPT_DIR}/..")
REPO_ROOT=$(git -C "${CHART_DIR}" rev-parse --show-toplevel)

# Relative path from repo root to the chart directory (used in git show paths)
CHART_PATH="${CHART_DIR#"${REPO_ROOT}/"}"

# Fetch the grafana/alloy Helm chart index and build a version→binary-version lookup file
INDEX_FILE=$(mktemp)
MAPPING_FILE=$(mktemp)
TGZ_FILE=$(mktemp)
trap 'rm -f "${INDEX_FILE}" "${MAPPING_FILE}" "${TGZ_FILE}"' EXIT

curl -sf https://grafana.github.io/helm-charts/index.yaml > "${INDEX_FILE}"

# Write "chartVersion binaryVersion" pairs (one per line) for later lookup
yq '.entries.alloy[] | .version + " " + .appVersion' "${INDEX_FILE}" > "${MAPPING_FILE}"

lookup_binary() {
    local chart_version="$1"
    grep "^${chart_version} " "${MAPPING_FILE}" | awk '{print $2}' | sed 's/^v//' | head -1
}

cat << 'HEADER'
# Versions

This document lists the component versions bundled with each release of the k8s-monitoring Helm chart since 3.0.

| k8s-monitoring | Alloy Operator | Alloy Chart | Alloy Binary |
|----------------|---------------|-------------|--------------|
HEADER

# Iterate over all 3.x and 4.x release tags (sorted by version, excluding RCs)
while IFS= read -r tag; do
    chart_version="${tag#k8s-monitoring-}"

    ao_version=$(git -C "${REPO_ROOT}" show "${tag}:${CHART_PATH}/Chart.yaml" 2>/dev/null \
        | yq '.dependencies[] | select(.name == "alloy-operator") | .version')

    if [[ -z "${ao_version}" ]]; then
        continue
    fi

    git -C "${REPO_ROOT}" show "${tag}:${CHART_PATH}/charts/alloy-operator-${ao_version}.tgz" \
        > "${TGZ_FILE}" 2>/dev/null

    alloy_chart_version=$(tar -xzOf "${TGZ_FILE}" alloy-operator/Chart.yaml 2>/dev/null \
        | yq '.appVersion')

    alloy_binary=$(lookup_binary "${alloy_chart_version}")

    echo "| ${chart_version} | ${ao_version} | ${alloy_chart_version} | ${alloy_binary} |"
done < <(
    git -C "${REPO_ROOT}" tag --list 'k8s-monitoring-[34]*' \
        | sed 's/\x1b\[[0-9;]*m//g; s/\x1b\[K//g' \
        | grep -v '\-rc\.' \
        | sort -V
)
