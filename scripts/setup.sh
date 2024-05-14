#!/usr/bin/env bash

source "./scripts/includes/utils.sh"

source "$(pwd)/tools/includes/logging.sh"

# output the heading
heading "K8s Monitoring Helm" "Performing Setup Checks"

# make sure helm exists
info "Checking to see if helm is installed"
if [[ "$(command -v helm)" = "" ]]; then
  warning "helm is required if running locally, see: (https://helm.sh) or run: brew install helm";
else
  success "helm is installed"
fi

# make sure helm-docs exists
info "Checking to see if helm-docs is installed"
if [[ "$(command -v helm-docs)" = "" ]]; then
  warning "helm-docs is required if running locally, see: (https://github.com/norwoodj/helm-docs) or run: brew install helm-docs";
else
  success "helm-docs is installed"
fi

# make sure chart-testing exists
if [[ "$(command -v ct)" = "" ]]; then
  warning "chart-testing is required if running locally, see: (https://github.com/helm/chart-testing) or run: brew install chart-testing";
else
  success "chart-testing is installed"
fi

# make sure docker exists
if [[ "$(command -v docker)" = "" ]]; then
  warning "docker is required if running locally, see: (https://docker.com) or run: brew install docker";
else
  success "docker is installed"
fi

# make sure alloy exists
info "Checking to see if alloy is installed"
if [[ "$(command -v alloy)" = "" ]]; then
  warning "alloy is required if running locally, see: (https://grafana.com/docs/alloy/latest/) or run: brew install grafana/grafana/alloy";
else
  success "alloy is installed"
fi

# make sure kind exists
info "Checking to see if kind is installed"
if [[ "$(command -v kind)" = "" ]]; then
  warning "kind is required if running locally, see: (https://kind.sigs.k8s.io/) or run: brew install kind";
else
  success "kind is installed"
fi

# make sure shellspec exists
info "Checking to see if shellspec is installed"
if [[ "$(command -v shellspec)" = "" ]]; then
  warning "shellspec is required if running locally, see: (https://shellspec.info/) or run: brew install shellspec";
else
  success "shellspec is installed"
fi

# make sure yamllint exists
info "Checking to see if shellspec is installed"
if [[ "$(command -v yamllint)" = "" ]]; then
  warning "yamllint is required if running locally, see: (https://github.com/adrienverge/yamllint) or run: brew install yamllint";
else
  success "yamllint is installed"
fi

# make sure yq exists
info "Checking to see if yq is installed"
if [[ "$(command -v yq)" = "" ]]; then
  warning "yq is required if running locally, see: (https://github.com/mikefarah/yq) or run: brew install yq";
else
  success "yq is installed"
fi

# make sure jq exists
info "Checking to see if yq is installed"
if [[ "$(command -v jq)" = "" ]]; then
  warning "jq is required if running locally, see: (https://jqlang.github.io/jq) or run: brew install jq";
else
  success "jq is installed"
fi

# make sure kubectl exists
info "Checking to see if kubectl is installed"
if [[ "$(command -v kubectl)" = "" ]]; then
  warning "kubectl is required if running locally, see: (https://kubernetes.io/docs/reference/kubectl/) or run: brew install kubectl";
else
  success "kubectl is installed"
fi

# make sure Node exists
info "Checking to see if Node is installed"
if [[ "$(command -v node)" = "" ]]; then
  warning "node is required if running locally, see: (https://nodejs.org) or run: brew install nvm && nvm install 18";
else
  success "node is installed"
fi

# make sure yarn exists
info "Checking to see if yarn is installed"
if [[ "$(command -v yarn)" = "" ]]; then
  warning "yarn is required if running locally, see: (https://yarnpkg.com) or run: brew install yarn";
else
  success "yarn is installed"
fi

# make sure shellcheck exists
info "Checking to see if shellcheck is installed"
if [[ "$(command -v shellcheck)" = "" ]]; then
  warning "shellcheck is required if running locally, see: (https://shellcheck.net) or run: brew install shellcheck";
else
  success "shellcheck is installed"
fi

# make sure misspell exists
info "Checking to see if misspell is installed"
if [[ "$(command -v misspell)" = "" ]]; then
  warning "misspell is required if running locally, see: (https://github.com/client9/misspell) or run: go install github.com/client9/misspell/cmd/misspell@latest";
else
  success "misspell is installed"
fi

# make sure actionlint exists
info "Checking to see if actionlint is installed"
if [[ "$(command -v actionlint)" = "" ]]; then
  warning "actionlint is required if running locally, see: (https://github.com/rhysd/actionlint) or run: go install github.com/rhysd/actionlint/cmd/actionlint@latest";
else
  success "actionlint is installed"
fi
