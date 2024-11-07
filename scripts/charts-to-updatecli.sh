#!/usr/bin/env bash

CHART_YAML=$1
if [ -z "$CHART_YAML" ]; then
  echo "Usage: $0 <path to Chart.yaml>"
  exit 1
fi
if [ ! -f "$CHART_YAML" ]; then
  echo "File not found: $CHART_YAML"
  exit 1
fi

rm -f .updatecli-*.yaml
chartDir=$(basename "$(dirname "$(readlink -f "$CHART_YAML")")")
dependencyCount=$(yq eval '.dependencies | length' "$CHART_YAML")
for ((i=0; i<dependencyCount; i++)); do
  dependency=$(yq eval ".dependencies[$i]" "$CHART_YAML")
  chart=$(echo "$dependency" | yq eval '.name')
  name=$(echo "$dependency" | yq eval ".alias // \"$chart\"")
  repository=$(echo "$dependency" | yq eval '.repository')
  if [[ "${repository}" == https://* ]]; then
    if [ ! -f ".updatecli-${chart}.yaml" ]; then
      echo "---" > ".updatecli-${chart}.yaml"
      yq eval --null-input "{
  \"name\": \"Update dependency \\\"$chart\\\" for Helm chart \\\"$chartDir\\\"\",
  \"sources\": {
    \"$chart\": {
      \"name\": \"Get latest \\\"$chart\\\" Helm chart version\",
      \"kind\": \"helmchart\",
      \"spec\": {
        \"name\": \"$chart\",
        \"url\": \"$repository\",
        \"versionfilter\": {
          \"kind\": \"semver\",
          \"pattern\": \"*\"
        }
      }
    }
  },
  \"conditions\": {
    \"$chart\": {
      \"name\": \"Ensure Helm chart dependency \\\"$chart\\\" is specified\",
      \"kind\": \"yaml\",
      \"spec\": {
        \"file\": \"charts/$chartDir/Chart.yaml\",
        \"key\": \"$.dependencies[$i].name\",
        \"value\": \"$chart\"
      },
      \"disablesourceinput\": true
    }
  },
  \"targets\": {}
}" >> ".updatecli-${chart}.yaml"
    fi
    yq eval ".targets += {
\"$name\": {
  \"name\": \"Bump Helm chart dependency \\\"$name\\\" for Helm chart \\\"$chartDir\\\"\",
  \"kind\": \"helmchart\",
  \"spec\": {
    \"file\": \"Chart.yaml\",
    \"key\": \"$.dependencies[$i].version\",
    \"name\": \"charts/$chartDir\",
    \"versionincrement\": \"none\"
  },
  \"sourceid\": \"$chart\"
}
}" ".updatecli-${chart}.yaml" > ".updatecli-${chart}.yaml-new"
    mv ".updatecli-${chart}.yaml-new" ".updatecli-${chart}.yaml"
  fi
done


