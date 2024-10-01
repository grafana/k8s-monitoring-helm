#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/includes/utils.sh"
source "${SCRIPT_DIR}/includes/logging.sh"

# output the heading
heading "Kubernetes Monitoring Helm" "Performing Shell Linting using shellcheck"

# check to see if shellcheck is installed
if [[ "$(command -v shellcheck || true)" = "" ]]; then
  emergency "shellcheck is required if running lint locally, see: (https://shellcheck.net) or run: brew install nvm && nvm install 18";
fi

# determine whether or not the script is called directly or sourced
(return 0 2>/dev/null) && sourced=1 || sourced=0

statusCode=0

# shellcheck disable=SC2046 disable=SC2312
shellcheck --rcfile="$(pwd)/.shellcheckrc" $(
    comm -23 <(
      find . -type f -name "*.sh" -not \( -path "./node_modules/*" -o -path "./data-alloy/*" -o -path "./.git/*" -o -path "./tests/spec/*" \) | \
        sort
      ) <(
      find . -type f -name "*.sh"  -not \( -path "./node_modules/*" -o -path "./data-alloy/*" -o -path "./.git/*" -o -path "./tests/spec/*" \) | \
        git check-ignore --stdin | \
        sort
      )
    )

echo ""
echo ""

# if the script was called by another, send a valid exit code
if [[ "${sourced}" == "1" ]]; then
  return "${statusCode}"
else
  exit "${statusCode}"
fi
