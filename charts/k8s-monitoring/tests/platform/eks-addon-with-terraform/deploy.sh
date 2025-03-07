#!/usr/bin/env bash

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "${TEST_DIR}" || exit 1

terraform init
terraform apply -auto-approve
