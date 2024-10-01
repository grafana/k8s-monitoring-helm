#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/includes/utils.sh"
source "${SCRIPT_DIR}/includes/logging.sh"

# output the heading
heading "Kubernetes Monitoring Helm" "Performing Shell Linting using actionlint"

# check to see if actionlint is installed
if [[ "$(command -v actionlint || true)" = "" ]]; then
  emergency "actionlint is required if running lint locally, see: (https://github.com/rhysd/actionlint) or run: go install github.com/rhysd/actionlint/cmd/actionlint@latest";
fi

# determine whether or not the script is called directly or sourced
(return 0 2>/dev/null) && sourced=1 || sourced=0

statusCode=0
actionlint .github/workflows/*.yml
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
