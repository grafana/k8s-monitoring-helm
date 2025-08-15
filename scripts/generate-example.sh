#!/usr/bin/env bash
set -eo pipefail  # Exit immediately if a command fails.

scriptDir=$(dirname "$(readlink -f "$0")")

usage() {
  echo "USAGE: generate-example.sh <chart-dir> <example-dir> [-o|--outputDir output-dir] [--no-alloy] [--no-readme]"
  echo ""
  echo "Generates the example files."
  echo ""
  echo "  <example-dir>     - The example directory."
  echo "                      Expects this file to exist:"
  echo "    values.yaml     - The test plan."
  echo "    description.txt - The example description, used for building the README.md."
  echo ""
  echo "  -o|--output-dir   - (Optional) The output directory. Defaults to the example directory."
  echo "  --no-alloy        - (Optional) Do not extract Alloy configuration files."
  echo "  --no-readme       - (Optional) Do not generate README.md file."
}

releaseName=k8smon

# Argument parsing
if [ "${1}" == "-h" ] || [ "${1}" == "-help" ] || [ "${1}" == "--help" ]; then
  usage
  exit 0
fi

chartDir=$1
if [ -z "${chartDir}" ]; then
  echo "Chart directory required!"
  usage
  exit 1
fi
if [ ! -d "${chartDir}" ]; then
  echo "Not a directory: ${chartDir}"
  usage
  exit 1
fi
shift
exampleDir=$1
if [ -z "${exampleDir}" ]; then
  echo "Example directory required!"
  usage
  exit 1
fi
if [ ! -d "${exampleDir}" ]; then
  echo "Not a directory: ${exampleDir}"
  usage
  exit 1
fi
shift

generateAlloyFiles=true
generateReadme=true
outputDir="${exampleDir}"
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output-dir)
      outputDir=$(realpath "${exampleDir}/$2")
      mkdir -p "${outputDir}"
      shift 2
      ;;
    --no-alloy)
      generateAlloyFiles=false
      shift 1
      ;;
    --no-readme)
      generateReadme=false
      shift 1
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

valuesFile="${exampleDir}/values.yaml"
if [ ! -f "${valuesFile}" ]; then
  echo "Values file not found: ${valuesFile}"
  usage
  exit 1
fi

descriptionFile="${exampleDir}/description.txt"
#if [ ! -f "${descriptionFile}" ]; then
#  echo "Description file not found: ${descriptionFile}"
#  usage
#  exit 1
#fi

# Start of script
outputFile="${outputDir}/output.yaml"
helm template "${releaseName}" "${chartDir}" -f "${valuesFile}" > "${outputFile}"

if [ "${generateReadme}" == "true" ]; then
  readmeFile="${exampleDir}/README.md"
  {
    echo '<!--'
    echo '(NOTE: Do not edit README.md directly. It is a generated file!)'
    echo '(      To make changes, please modify values.yaml or description.txt and run `make examples`)'
    echo '-->'
    if [ -f "${descriptionFile}" ]; then
      cat "${descriptionFile}"
    else
      echo "Warning, missing description.txt in ${exampleDir}, please consider adding one!" >&2
      echo "# Example: ${exampleDir##*/}"
    fi
    echo ''
    echo '## Values'
    echo ''
    echo '<!-- textlint-disable terminology -->'
    echo '```yaml'
    cat "${valuesFile}"
    echo '```'
    echo '<!-- textlint-enable terminology -->'
  } > "${readmeFile}"
fi

if [ "${generateAlloyFiles}" == "true" ]; then
  alloyInstances=("alloy-metrics" "alloy-logs" "alloy-singleton" "alloy-receiver" "alloy-profiles")
  for alloyInstance in "${alloyInstances[@]}"; do
    enabled=$(yq eval ".[\"${alloyInstance}\"].enabled // false" "${valuesFile}")
    if [ "${enabled}" == "true" ]; then
      alloyConfigFile="${outputDir}/${alloyInstance}.alloy"
      yq "select(.kind==\"ConfigMap\" and .metadata.name==\"${releaseName}-${alloyInstance}\") | .data[\"config.alloy\"]" "${outputFile}" > "${alloyConfigFile}"
    fi
  done
fi
