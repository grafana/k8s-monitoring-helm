#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/includes/utils.sh"
source "${SCRIPT_DIR}/includes/logging.sh"

# output the heading
heading "Kubernetes Monitoring Helm" "Performing Misspell Linting using misspell"

# check to see if misspell is installed
if [[ "$(command -v misspell || true)" = "" ]]; then
  emergency "misspell is required if running lint locally, see: (https://github.com/client9/misspell) or run: go install github.com/client9/misspell/cmd/misspell@latest";
fi

# determine whether or not the script is called directly or sourced
(return 0 2>/dev/null) && sourced=1 || sourced=0

statusCode=0

# shellcheck disable=SC2046 disable=SC2312
misspell --error --locale US $(
    comm -23 <(
      find . -type f -not \( -path "./node_modules/*" -o -path "./data-alloy/*" -o -path "./.git/*" -o -name output.yaml -o -name .textlintrc \) | \
        sort
      ) <(
      find . -type f -not \( -path "./node_modules/*" -o -path "./data-alloy/*" -o -path "./.git/*" -o -name output.yaml -o -name .textlintrc \) | \
        git check-ignore --stdin | \
        sort
      )
    )

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
