#!/usr/bin/env bash

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "${TEST_DIR}" || exit 1

set -eo pipefail

CURRENT_VERSION="$(yq eval '.version' ../../../../Chart.yaml)"
IFS='.' read -r major minor patch <<< "${CURRENT_VERSION}"
if [ "${patch}" -eq 0 ]; then
  echo "Patch version is 0. This test is not applicable."
  exit 1
else
  PREVIOUS_PATCH_RELEASE="${major}.${minor}.$((patch - 1))"
fi

echo "---"
echo "subject:"
echo "  version: ${PREVIOUS_PATCH_RELEASE}"
