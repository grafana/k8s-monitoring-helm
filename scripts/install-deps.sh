#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
  echo "Using brew to install dependencies"
  brew install chart-testing grafana/grafana/alloy helm norwoodj/tap/helm-docs shellspec yamllint python-yq
else 
  echo "Not on a Mac, skipping brew installs"
fi