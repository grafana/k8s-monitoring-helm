#!/usr/bin/env bash
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PARENT_DIR}/scripts/includes/utils.sh"
source "${PARENT_DIR}/scripts/includes/logging.sh"

# output the heading
heading "Kubernetes Monitoring Helm" "Performing Terraform Linting using tflint"

dir=$(pwd || true)

# check to see if tflint is installed
if [[ "$(command -v tflint || true)" = "" ]]; then
  emergency "tflint is required if running lint locally.  Run: brew install tflint";
fi

# determine whether or not the script is called directly or sourced
(return 0 2>/dev/null) && sourced=1 || sourced=0

terraformDirectories=$(find . -name 'vars.tf' -exec dirname {} \;)

statusCode=0
for dir in ${terraformDirectories}; do
  tflint --chdir "${dir}"
  currentCode="$?"
  if [[ "${statusCode}" == 0 ]]; then
    statusCode="${currentCode}"
  fi
done

if [[ "${statusCode}" == "0" ]]; then
  echo "no issues found"
  echo ""
fi

echo ""

# if the script was called by another, send a valid exit code
if [[ "${sourced}" == "1" ]]; then
  return "${statusCode}"
else
  exit "${statusCode}"
fi
