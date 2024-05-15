#!/usr/bin/env bash

source "./scripts/includes/utils.sh"
source "./scripts/includes/logging.sh"

# output the heading
heading "Kubernetes Monitoring Helm" "Performing Editorconfig Linting using editorconfig-checker"

dir=$(pwd || true)

# check to see if remark is installed
if [[ ! -f "${dir}"/node_modules/.bin/editorconfig-checker ]]; then
  emergency "editorconfig-checker node module is not installed, please run: make install";
fi

# determine whether or not the script is called directly or sourced
(return 0 2>/dev/null) && sourced=1 || sourced=0

statusCode=0
./node_modules/.bin/editorconfig-checker -config="${dir}/.ecrc"
currentCode="$?"
# only override the statusCode if it is 0
if [[ "${statusCode}" == 0 ]]; then
  statusCode="${currentCode}"
fi

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
