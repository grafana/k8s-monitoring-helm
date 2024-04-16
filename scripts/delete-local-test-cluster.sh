#!/bin/bash

CLUSTER_NAME="k8s-mon-test-cluster"

kind delete cluster --name "${CLUSTER_NAME}"
