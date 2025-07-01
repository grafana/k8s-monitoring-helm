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

##@ Build
.PHONY: clean
clean: ## Clean all charts
	rm -rf node_modules
	set -e && \
	for chart in $(CHARTS); do \
		make -C charts/$$chart $@; \
	done

##@ Build
.PHONY: build
build: check-helm-version ## Build all charts
	set -e && \
	for chart in $(CHARTS); do \
		make -C charts/$$chart $@; \
	done

##@ Install
.PHONY: install
install: ## Install dependencies
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
lint: lint-alloy lint-shell lint-markdown lint-terraform lint-text lint-yaml lint-alex lint-misspell lint-actionlint lint-zizmor ## Run all linters

.PHONY: lint-alloy
ALLOY_FILES = $(shell find . -name "*.alloy" ! -path "./data-alloy/*")
lint-alloy: ## Lint Alloy files
	@./scripts/lint-alloy.sh $(ALLOY_FILES)
	rm -rf data-alloy  # Clean up temporary Alloy data directory

.PHONY: lint-shell
SHELL_SCRIPTS = $(shell find . -type f -name "*.sh" -not \( -path "./node_modules/*" -o -path "./data-alloy/*" -o -path "./.git/*" -o -path "./charts/k8s-monitoring-v1/test/spec/*" -o -path "./charts/k8s-monitoring/tests/example-checks/spec/*" -o -path "./charts/k8s-monitoring/tests/misc-checks/spec/*" \))
lint-shell: ## Lint shell scripts
	@if command -v shellcheck &> /dev/null; then \
		shellcheck --rcfile .shellcheckrc $(SHELL_SCRIPTS); \
	else \
		docker run --rm -v $(shell pwd):/src --workdir /src koalaman/shellcheck:stable --rcfile .shellcheckrc $(SHELL_SCRIPTS); \
	fi

.PHONY: lint-markdown
lint-markdown: node_modules/.bin/markdownlint-cli2 ## Lint markdown files
	@node_modules/.bin/markdownlint-cli2 $(shell find . -name "*.md" ! -path "./node_modules/*" ! -path "./data-alloy/*" ! -path "./charts/**/data-alloy/*")

TERRAFORM_DIRS = $(shell find . -name 'vars.tf' -exec dirname {} \;)
.PHONY: lint-terraform
lint-terraform: ## Lint terraform files
	@for dir in $(TERRAFORM_DIRS); do \
		if command -v tflint &> /dev/null; then \
			tflint --chdir "$${dir}"; \
		else \
			docker run --rm -v $(shell pwd)/$${dir}:/data ghcr.io/terraform-linters/tflint; \
		fi; \
	done

.PHONY: lint-text
lint-text: node_modules/.bin/textlint ## Lint text files
	@node_modules/.bin/textlint --config .textlintrc --ignore-path .textlintignore .

.PHONY: lint-yaml
lint-yaml: ## Lint yaml files
	@if command -v yamllint &> /dev/null; then \
		yamllint --strict --config-file .yamllint.yml .; \
	else \
		docker run --rm -v $(shell pwd):/data cytopia/yamllint:latest --config-file .yamllint.yml .; \
	fi

.PHONY: lint-alex
lint-alex: node_modules/.bin/alex ## Check for insensitive language
	@node_modules/.bin/alex $(shell find . -type f -name "*.md" ! -path "./node_modules/*" ! -path "./data-alloy/*" ! -path "./CODE_OF_CONDUCT.md")

.PHONY: lint-misspell
ALL_FILES_FOR_SPELLCHECK = $(shell find . -type f -not \( -path "./node_modules/*" -o -path "./data-alloy/*" -o -path "./.git/*" -o -name output.yaml -o -name .textlintrc \) )
lint-misspell: ## Check for common misspellings
	@if command -v misspell &> /dev/null; then \
		misspell --error --locale US $(ALL_FILES_FOR_SPELLCHECK); \
	else \
		echo "misspell is required if running lint locally, see: (https://github.com/golangci/misspell) or run: go install github.com/golangci/misspell/cmd/misspell@latest"; \
		exit 1; \
	fi

.PHONY: lint-actionlint
lint-actionlint: ## Lint GitHub Action workflows
	@if command -v actionlint &> /dev/null; then \
		actionlint .github/workflows/*.yml .github/workflows/*.yaml; \
	else \
		docker run --rm -v $(shell pwd):/src --workdir /src rhysd/actionlint:latest .github/workflows/*.yml .github/workflows/*.yaml; \
	fi

.PHONY: lint-zizmor
lint-zizmor: ## Statically analyze GitHub Action workflows
	@if command -v zizmor&> /dev/null; then \
		zizmor .; \
	else \
		docker run --rm -v $(shell pwd):/src --workdir /src ghcr.io/zizmorcore/zizmor:latest .; \
	fi


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
