#!/usr/bin/env bash

# Generates docs/collectors/presets/README.md from collectors/presets/*.yaml.
# Descriptions come from the first "# -- ..." comment line in each file.
# A sizing table is built from the small/medium/large/xlarge preset files.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CHART_DIR=$(realpath "${SCRIPT_DIR}/..")
PRESETS_DIR="${CHART_DIR}/collectors/presets"

# Extract description: joins the first "# -- " comment line with any immediately
# following "# " continuation lines (stopping at "# @" section tags or non-comments).
get_description() {
    awk '
        /^# -- / { in_desc=1; sub(/^# -- /, ""); printf "%s", $0; next }
        in_desc && /^# [^@]/ { sub(/^# /, ""); printf " %s", $0; next }
        in_desc { print ""; exit }
    ' "$1"
}

cat << 'EOF'
# Collector Presets

Presets are a way to set predefined configurations for Alloy collectors.

## Current presets

| Preset | Description |
|--------|-------------|
EOF

# Alphabetical order matches `ls` / `sort` default
for preset_file in "${PRESETS_DIR}"/*.yaml; do
    preset_name=$(basename -s .yaml "${preset_file}")
    description=$(get_description "${preset_file}")
    echo "| [${preset_name}](${preset_name}.md) | ${description} |"
done

cat << 'EOF'

## Collector sizing

The following presets set resource requests and limits for Alloy collectors. Choose the size
that best matches your cluster size and telemetry workload.

| Size | CPU Request | Memory Request | CPU Limit | Memory Limit |
|------|-------------|----------------|-----------|--------------|
EOF

for size in small medium large xlarge; do
    preset_file="${PRESETS_DIR}/${size}.yaml"
    cpu_req=$(yq '.alloy.resources.requests.cpu' "${preset_file}")
    mem_req=$(yq '.alloy.resources.requests.memory' "${preset_file}")
    cpu_lim=$(yq '.alloy.resources.limits.cpu' "${preset_file}")
    mem_lim=$(yq '.alloy.resources.limits.memory' "${preset_file}")
    echo "| [${size}](${size}.md) | ${cpu_req} | ${mem_req} | ${cpu_lim} | ${mem_lim} |"
done
