#!/usr/bin/env bash
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/utils.sh"
source "${PARENT_DIR}/scripts/includes/logging.sh"

# output the heading
heading "Kubernetes Monitoring Helm" "Generating JSON Schema for Helm Charts"

CHART_DIR=$1
HAS_HELM_SCHEMA_GEN=$(helm plugin list | grep -c "schema-gen")

if [ -z "${CHART_DIR}" ]; then
  echo "Chart directory not defined!"
  exit 1
fi

if [ ! -d "${CHART_DIR}" ]; then
  echo "${CHART_DIR} is not a directory!"
  exit 1
fi

set -eo pipefail  # Exit immediately if a command fails.
shopt -s nullglob # Required when a chart does not use mod files.

# Generate base schema from the values file.
if [ "${HAS_HELM_SCHEMA_GEN}" -eq "1" ]; then
  helm schema-gen "${CHART_DIR}/values.yaml" > "${CHART_DIR}/values.schema.generated.json"
else
  docker run --rm \
    --platform linux/amd64 \
    --volume "$(pwd)/${CHART_DIR}:/chart" \
    --entrypoint sh \
    alpine/helm \
    -c 'helm plugin install https://github.com/karuppiah7890/helm-schema-gen.git && helm schema-gen /chart/values.yaml > /chart/values.schema.generated.json'
fi

if [ -d "${CHART_DIR}/schema-mods" ]; then
  if [ -d "${CHART_DIR}/schema-mods/definitions" ]; then
    # Add definitions to the schema.
    for file in "${CHART_DIR}"/schema-mods/definitions/*.schema.json; do
      echo "Setting definition for ${file}..."
      name=$(basename "$file" .schema.json)
      jq --indent 4 \
        --arg name "${name}" \
        --slurpfile data "$file" \
        '.definitions[$name] = $data[0]' \
        "${CHART_DIR}/values.schema.generated.json" > "${CHART_DIR}/values.schema.modded.json"
      mv "${CHART_DIR}/values.schema.modded.json" "${CHART_DIR}/values.schema.generated.json"
    done
  fi

  # Applying JQ mods...
  for file in "${CHART_DIR}"/schema-mods/*.jq; do
    echo "Applying JQ mod for ${file}..."
    jq --indent 4 --from-file "$file" "${CHART_DIR}/values.schema.generated.json" > "${CHART_DIR}/values.schema.modded.json"
    mv "${CHART_DIR}/values.schema.modded.json" "${CHART_DIR}/values.schema.generated.json"
  done

  # Applying JSON mods...
  for file in "${CHART_DIR}"/schema-mods/*.json; do
    echo "Applying JSON mod for ${file}..."
    jq --indent 4 -s '.[0] * .[1]' "${CHART_DIR}/values.schema.generated.json" "$file" > "${CHART_DIR}/values.schema.modded.json"
    mv "${CHART_DIR}/values.schema.modded.json" "${CHART_DIR}/values.schema.generated.json"
  done
fi

mv "${CHART_DIR}/values.schema.generated.json" "${CHART_DIR}/values.schema.json"
echo "Done: ${CHART_DIR}/values.schema.json"
