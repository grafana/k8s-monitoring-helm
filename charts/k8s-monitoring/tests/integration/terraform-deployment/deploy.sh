#!/usr/bin/env bash

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pushd "${TEST_DIR}" || exit 1
kind get kubeconfig --name="$(yq '.cluster.name' values.yaml)" > kubeconfig.yaml
terraform init
terraform apply -auto-approve
