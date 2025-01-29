#!/bin/bash

usage() {
  echo "USAGE: create-docs-and-schema.sh <name> <kind>"
  echo "Creates the docs and schema for a values file snippet"
  echo ""
  echo "<kind> is the kind of resource (e.g. destination, collector)"
  echo ""
  echo "Expects a file at /src/<kind>s/<name>-values.yaml"
  echo "Looks for an optional file at /src/docs/<kind>s/.doc_templates/<name>.gotmpl"
  echo "Will write the doc to /src/docs/<kind>s/<name>.md"
  echo "Will write the schema to /src/schema-mods/definitions/<name>-<kind>.schema.json"
}

NAME=$1
KIND=$2
INPUT_VALUES=/src/${KIND}s/${NAME}-values.yaml
INPUT_TEMPLATE=/src/docs/${KIND}s/.doc_templates/${NAME}.gotmpl
OUTPUT_DOCS=/src/docs/${KIND}s/${NAME}.md
OUTPUT_SCHEMA=/src/schema-mods/definitions/${NAME}-${KIND}.schema.json

if [ -z "${NAME}" ]; then
  echo "Name not defined!"
  usage
  exit 1
fi

if [ -z "${KIND}" ]; then
  echo "Name not defined!"
  usage
  exit 1
fi

if [ ! -f "${INPUT_VALUES}" ]; then
  echo "${INPUT_VALUES} is not a file!"
  usage
  exit 1
fi

set -eo pipefail

echo "Creating temporary Helm chart for ${NAME}..."
helm create "/tmp/${NAME}"
cd "/tmp/${NAME}"

echo "Creating docs..."
cp "${INPUT_VALUES}" values.yaml
if [ -f "${INPUT_TEMPLATE}" ]; then
  cp "${INPUT_TEMPLATE}" README.md.gotmpl
else
  echo "# ${NAME}" > README.md.gotmpl
  echo "" >> README.md.gotmpl
  echo '{{ template "chart.valuesSection" . }}' >> README.md.gotmpl
fi

helm-docs
mv README.md "${OUTPUT_DOCS}"

echo "Creating schema..."
helm schema-gen values.yaml > "${OUTPUT_SCHEMA}"
jq --indent 4 --arg name "${NAME}" \
  'del(.["$schema"])
  | .properties.name = {"type": "string"}
  | .properties.type = {"type": "string", "const": $name}' \
   "${OUTPUT_SCHEMA}" > "${OUTPUT_SCHEMA}.tmp"
mv "${OUTPUT_SCHEMA}.tmp" "${OUTPUT_SCHEMA}"