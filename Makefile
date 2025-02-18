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

.PHONY: test
test: build lint
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

####################################################################
#                           Linting                                #
####################################################################
.PHONY: lint lint-sh lint-md lint-txt lint-yml lint-alex lint-misspell lint-actionlint
lint: lint-sh lint-md lint-txt lint-yml lint-alex lint-misspell lint-actionlint

# Shell Linting for checking shell scripts
lint-sh lint-shell:
	@./scripts/lint-shell.sh

# Markdown Linting for checking markdown files
lint-md lint-markdown: node_modules/.bin/markdownlint-cli2
	@./scripts/lint-markdown.sh

# Text Linting for checking text files
lint-txt lint-text: node_modules/.bin/textlint
	@./scripts/lint-text.sh

# Yaml Linting for checking yaml files
lint-yml lint-yaml:
	@./scripts/lint-yaml.sh

# Alex Linting for checking insensitive language
lint-alex: node_modules/.bin/alex
	@./scripts/lint-alex.sh || true

# Misspell Linting for checking common spelling mistakes
lint-misspell:
	@./scripts/lint-misspell.sh

# Actionlint Linting for checking GitHub Actions
lint-al lint-actionlint:
	@./scripts/lint-actionlint.sh
