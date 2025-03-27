SHELL := /bin/bash
UNAME := $(shell uname)

CHARTS = $(shell ls --color=never charts)
HELM_VERSION = $(shell helm version --short)
HELM_MAJOR_VERSION = $(shell echo $(HELM_VERSION) | cut -d '.' -f 1 | sed -e 's/v//')
HELM_MINOR_VERSION = $(shell echo $(HELM_VERSION) | cut -d '.' -f 2)
HELM_REQUIRED_MAJOR_VERSION = 3
HELM_REQUIRED_MINOR_VERSION = 14

.PHONY: check-helm-version
check-helm-version:
	@if [ "$(HELM_MAJOR_VERSION)" -lt "$(HELM_REQUIRED_MAJOR_VERSION)" ] || [ "$(HELM_MINOR_VERSION)" -lt "$(HELM_REQUIRED_MINOR_VERSION)" ]; then \
		echo "This project requires Helm v$(HELM_REQUIRED_MAJOR_VERSION).$(HELM_REQUIRED_MINOR_VERSION)."; \
		echo "You are currently using version v$(HELM_MAJOR_VERSION).$(HELM_MINOR_VERSION)."; \
		echo "Please install the latest version of the Helm CLI."; \
		echo "  https://helm.sh/docs/intro/install/"; \
		exit 1; \
	fi

.PHONY: clean
clean:
	rm -rf node_modules
	set -e && \
	for chart in $(CHARTS); do \
		make -C charts/$$chart $@; \
	done

.PHONY: build
build: check-helm-version
	set -e && \
	for chart in $(CHARTS); do \
		make -C charts/$$chart $@; \
	done

####################################################################
#                   Installation / Setup                           #
####################################################################
.PHONY: setup install-deps
setup install-deps:
ifeq ($(UNAME), Darwin)
	@./scripts/setup.sh
else
	echo "Not on MacOS, you'll have to just install things manually for now."
	exit 1
endif

.PHONY: install
install:
	yarn install

node_modules/.bin/alex: package.json yarn.lock
	yarn install

node_modules/.bin/markdownlint-cli2: package.json yarn.lock
	yarn install

node_modules/.bin/textlint: package.json yarn.lock
	yarn install

##@ Tests
.PHONY: test
test: build lint ## Run tests for all charts
	set -e && \
	for chart in $(CHARTS); do \
		make -C charts/$$chart $@; \
	done

.PHONY: lint
lint: lint-alloy lint-shell lint-markdown lint-terraform lint-text lint-yaml lint-alex lint-misspell lint-actionlint ## Run all linters

.PHONY: lint-alloy
ALLOY_FILES := $(shell find . -name "*.alloy" ! -path "./data-alloy/*")
lint-alloy: ## Lint Alloy files
	@./scripts/lint-alloy.sh $(ALLOY_FILES)
	rm -rf data-alloy  # Clean up temporary Alloy data directory

.PHONY: lint-shell
lint-shell: ## Lint shell scripts
	@./scripts/lint-shell.sh

.PHONY: lint-markdown
lint-markdown: node_modules/.bin/markdownlint-cli2 ## Lint markdown files
	@./scripts/lint-markdown.sh

.PHONY: lint-terraform
lint-terraform: ## Lint terraform files
	@./scripts/lint-terraform.sh

.PHONY: lint-text
lint-text: node_modules/.bin/textlint ## Lint text files
	@./scripts/lint-text.sh

.PHONY: lint-yaml
lint-yaml: ## Lint yaml files
	@./scripts/lint-yaml.sh

.PHONY: lint-alex
lint-alex: node_modules/.bin/alex ## Check for insensitive language
	@./scripts/lint-alex.sh

.PHONY: lint-misspell
lint-misspell: ## Check for common misspellings
	@./scripts/lint-misspell.sh

.PHONY: lint-actionlint
lint-actionlint: ## Lint GitHub Action workflows
	@./scripts/lint-actionlint.sh


##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
