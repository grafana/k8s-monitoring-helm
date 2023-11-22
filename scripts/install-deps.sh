#!/bin/bash

if [ "$(uname)" == "Darwin" ]; then
  echo "Using brew to install dependencies"
  brew install chart-testing grafana-agent helm norwoodj/tap/helm-docs shellspec yamllint python-yq
else 
  echo "Not on a Mac, skipping brew installs"
fi