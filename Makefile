SHELL := /bin/bash

HELM_VERSION ?= $(shell helm version --short)
HELM_MAJOR_VERSION = $(shell echo $(HELM_VERSION) | cut -d '.' -f 1 | sed -e 's/v//')
HELM_MINOR_VERSION = $(shell echo $(HELM_VERSION) | cut -d '.' -f 2)
HELM_REQUIRED_MAJOR_VERSION = 3
HELM_REQUIRED_MINOR_VERSION = 14

.PHONY: check-helm-version
check-helm-version:
	@if [ "$(HELM_MAJOR_VERSION)" -lt "$(HELM_REQUIRED_MAJOR_VERSION)" ]; then \
		echo "This project requires Helm v$(HELM_REQUIRED_MAJOR_VERSION).$(HELM_REQUIRED_MINOR_VERSION)."; \
		echo "You are currently using version v$(HELM_MAJOR_VERSION).$(HELM_MINOR_VERSION)."; \
		echo "Please install a newer version of the Helm CLI."; \
		echo "  https://helm.sh/docs/intro/install/"; \
		exit 1; \
	elif [ "$(HELM_MAJOR_VERSION)" -eq "$(HELM_REQUIRED_MAJOR_VERSION)" ] && [ "$(HELM_MINOR_VERSION)" -lt "$(HELM_REQUIRED_MINOR_VERSION)" ]; then \
		echo "This project requires Helm v$(HELM_REQUIRED_MAJOR_VERSION).$(HELM_REQUIRED_MINOR_VERSION)."; \
		echo "You are currently using version v$(HELM_MAJOR_VERSION).$(HELM_MINOR_VERSION)."; \
		echo "Please install a newer version of the Helm CLI."; \
		echo "  https://helm.sh/docs/intro/install/"; \
		exit 1; \
	fi

##@ Build
.PHONY: clean
clean: ## Clean all charts
	$(MAKE) -C charts/k8s-monitoring $@;

##@ Build
.PHONY: build
build: check-helm-version ## Build all charts
	$(MAKE) -C charts/k8s-monitoring $@;

##@ Keys
.PHONY: update-signing-keys
update-signing-keys: keys/grafana-helm-charts-pubkey.gpg keys/prometheus-community-pubkey.gpg ## Refresh signing keys in keys/ (Grafana key requires the op CLI)

keys/grafana-helm-charts-pubkey.gpg:
	op --account grafana.1password.com read "op://Helm Maintainers/Helm Chart Signing Key/gpg-public-key.asc" | gpg --dearmor > keys/grafana-helm-charts-pubkey.gpg

keys/prometheus-community-pubkey.gpg:
	curl -sL https://prometheus-community.github.io/helm-charts/pubkey.gpg | gpg --dearmor > keys/prometheus-community-pubkey.gpg

##@ Tests
.PHONY: test
test: build lint ## Run tests for all charts
	$(MAKE) -C charts/k8s-monitoring $@;

.PHONY: lint
lint: lint-alloy lint-shell lint-markdown lint-terraform lint-text lint-yaml lint-alex lint-misspell lint-actionlint lint-zizmor ## Run all linters

.PHONY: lint-alloy
ALLOY_FILES = $(shell find . -name "*.alloy" ! -path "./data-alloy/*")
lint-alloy: ## Lint Alloy files
	@./scripts/lint-alloy.sh $(ALLOY_FILES)
	rm -rf data-alloy  # Clean up temporary Alloy data directory

.PHONY: lint-shell
# renovate: datasource=docker depName=koalaman/shellcheck
SHELLCHECK_VERSION = v0.11.0
SHELL_SCRIPTS = $(shell find . -type f -name "*.sh" -not \( -path "./node_modules/*" -o -path "./data-alloy/*" -o -path "./.git/*" -o -path "./charts/k8s-monitoring-v1/test/spec/*" -o -path "./charts/k8s-monitoring/tests/example-checks/spec/*" -o -path "./charts/k8s-monitoring/tests/misc-checks/spec/*" \))
lint-shell: ## Lint shell scripts
	@if command -v shellcheck &> /dev/null; then \
		shellcheck $(SHELL_SCRIPTS); \
	else \
		docker run --rm -v $(shell pwd):/src --workdir /src koalaman/shellcheck:$(SHELLCHECK_VERSION) --rcfile .shellcheckrc $(SHELL_SCRIPTS); \
	fi

.PHONY: lint-markdown
# renovate: datasource=docker depName=davidanson/markdownlint-cli2
MARKDOWNLINT_CLI2_VERSION = v0.23.1
MARKDOWN_FILES = $(shell find . -name "*.md" ! -path "./.context/*" ! -path "./version-4.0-development-plan/*" ! -path "./node_modules/*" ! -path "./data-alloy/*" ! -path "./charts/**/data-alloy/*" ! -path "./charts/k8s-monitoring/docs/create-a-new-feature/*")
lint-markdown: ## Lint markdown files
	@if command -v markdownlint-cli2 &> /dev/null; then \
		markdownlint-cli2 $(MARKDOWN_FILES); \
	else \
		docker run --rm -v $(shell pwd):/workdir davidanson/markdownlint-cli2:$(MARKDOWNLINT_CLI2_VERSION) $(MARKDOWN_FILES); \
	fi

TERRAFORM_DIRS = $(shell find . -name 'vars.tf' -exec dirname {} \;)
.PHONY: lint-terraform
# renovate: datasource=docker depName=ghcr.io/terraform-linters/tflint
TFLINT_VERSION = v0.64.0
lint-terraform: ## Lint terraform files
	@for dir in $(TERRAFORM_DIRS); do \
		if command -v tflint &> /dev/null; then \
			tflint --chdir "$${dir}"; \
		else \
			docker run --rm -v $(shell pwd)/$${dir}:/data ghcr.io/terraform-linters/tflint:$(TFLINT_VERSION); \
		fi; \
	done

# The textlint image is built locally from scripts/textlint/Dockerfile because no
# published image bundles the rules this repository uses. Renovate tracks the
# textlint and rule versions inside that Dockerfile.
TEXTLINT_IMAGE = k8s-monitoring/textlint

.PHONY: lint-text
lint-text: ## Lint text files
	@if command -v textlint &> /dev/null; then \
		echo "Linting text files with textlint..."; \
		textlint --config .textlintrc --ignore-path .textlintignore .; \
	else \
		echo "Building the textlint image..."; \
		docker build -t $(TEXTLINT_IMAGE) scripts/textlint && \
		echo "Linting text files with textlint..." && \
		docker run --rm -v $(shell pwd):/data --workdir /data $(TEXTLINT_IMAGE) --config .textlintrc --ignore-path .textlintignore .; \
	fi

.PHONY: lint-check-dead-links
lint-check-dead-links: ## Lint text files and check for dead links
	@if command -v textlint &> /dev/null; then \
		echo "Checking for dead links with textlint..."; \
		textlint --config .textlintrc-dead-links --ignore-path .textlintignore .; \
	else \
		echo "Building the textlint image..."; \
		docker build -t $(TEXTLINT_IMAGE) scripts/textlint && \
		echo "Checking for dead links with textlint..." && \
		docker run --rm -v $(shell pwd):/data --workdir /data $(TEXTLINT_IMAGE) --config .textlintrc-dead-links --ignore-path .textlintignore .; \
	fi

.PHONY: lint-yaml
# renovate: datasource=docker depName=cytopia/yamllint
YAMLLINT_VERSION = 1-0.10
lint-yaml: ## Lint yaml files
	@if command -v yamllint &> /dev/null; then \
		yamllint --strict --config-file .yamllint.yml .; \
	else \
		docker run --rm -v $(shell pwd):/data cytopia/yamllint:$(YAMLLINT_VERSION) --config-file .yamllint.yml .; \
	fi

.PHONY: lint-alex
# renovate: datasource=docker depName=pipelinecomponents/alex
ALEX_VERSION = 0.24.31
ALEX_FILES = $(shell find . -type f -name "*.md" ! -path "./node_modules/*" ! -path "./data-alloy/*" ! -path "./.context/*" ! -path "./CODE_OF_CONDUCT.md" ! -name "CHANGELOG.md")
lint-alex: ## Check for insensitive language
	@if command -v alex &> /dev/null; then \
		alex $(ALEX_FILES); \
	else \
		docker run --rm -v $(shell pwd):/code pipelinecomponents/alex:$(ALEX_VERSION) alex $(ALEX_FILES); \
	fi

.PHONY: lint-misspell
ALL_FILES_FOR_SPELLCHECK = $(shell find . -type f -name "*.md" -not \( -path "./node_modules/*" -o -path "./data-alloy/*" -o -path "./.context/*" -o -path "./.git/*" -o -name output.yaml -o -name .textlintrc \) )
lint-misspell: ## Check for common misspellings
	@if command -v misspell &> /dev/null; then \
		misspell --error --locale US $(ALL_FILES_FOR_SPELLCHECK); \
	else \
		echo "misspell is required if running lint locally, see: (https://github.com/golangci/misspell) or run: go install github.com/golangci/misspell/cmd/misspell@latest"; \
		exit 1; \
	fi

.PHONY: lint-actionlint
# renovate: datasource=docker depName=rhysd/actionlint
ACTIONLINT_VERSION = 1.7.12
lint-actionlint: ## Lint GitHub Action workflows
	@if command -v actionlint &> /dev/null; then \
		actionlint .github/workflows/*.yml .github/workflows/*.yaml; \
	else \
		docker run --rm -v $(shell pwd):/src --workdir /src rhysd/actionlint:$(ACTIONLINT_VERSION) .github/workflows/*.yml .github/workflows/*.yaml; \
	fi

.PHONY: lint-zizmor
# renovate: datasource=docker depName=ghcr.io/zizmorcore/zizmor
ZIZMOR_VERSION = 1.27.0
lint-zizmor: ## Statically analyze GitHub Action workflows
	@if command -v zizmor&> /dev/null; then \
		zizmor .; \
	else \
		docker run --rm -v $(shell pwd):/src --workdir /src ghcr.io/zizmorcore/zizmor:$(ZIZMOR_VERSION) .; \
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
