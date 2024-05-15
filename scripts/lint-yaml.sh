#!/usr/bin/env bash

source "./scripts/includes/utils.sh"
source "./scripts/includes/logging.sh"

# output the heading
heading "Kubernetes Monitoring Helm" "Onboarding - Performing YAML Linting using yamllint"

# make sure yamllint exists
if [[ "$(command -v yamllint || true)" = "" ]]; then
  echo >&2 "pipeyamllintnv command is required, see (https://pypi.org/project/yamllint/) or run: brew install yamllint";
  exit 1;
fi

# determine whether or not the script is called directly or sourced
(return 0 2>/dev/null) && sourced=1 || sourced=0

# run yamllint
yamllint --strict --config-file "$(pwd)/.yamllint.yml" .
statusCode="$?"

if [[ "$statusCode" == "0" ]]; then
  echo "no issues found"
  echo ""
fi

# if the script was called by another, send a valid exit code
if [[ "$sourced" == "1" ]]; then
  return "$statusCode"
fi
