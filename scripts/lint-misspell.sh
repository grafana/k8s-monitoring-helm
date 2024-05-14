#!/usr/bin/env bash

source "./scripts/includes/utils.sh"

source "./scripts/includes/logging.sh"

# output the heading
heading "Kubernetes Monitoring Helm" "Performing Shell Linting using misspell"

# check to see if misspell is installed
if [[ "$(command -v misspell || true)" = "" ]]; then
  emergency "misspell is required if running lint locally, see: (https://github.com/client9/misspell) or run: go install github.com/client9/misspell/cmd/misspell@latest";
fi

# determine whether or not the script is called directly or sourced
(return 0 2>/dev/null) && sourced=1 || sourced=0

statusCode=0
misspell --locale US ./*.md ./**[!node_modules]/*.md ./**[!node_modules]/**/*.md ./**[!node_modules]/**/**/*.md
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
echo ""

# if the script was called by another, send a valid exit code
if [[ "${sourced}" == "1" ]]; then
  return "${statusCode}"
else
  exit "${statusCode}"
fi
