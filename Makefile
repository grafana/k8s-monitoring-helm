SHELL := /bin/bash
UNAME := $(shell uname)

FEATURE_CHARTS = $(shell ls charts | grep -v k8s-monitoring)

.PHONY: build
build:
	set -e && \
	for chart in $(FEATURE_CHARTS); do \
		make -C charts/$$chart build; \
	done
	make -C charts/k8s-monitoring build

.PHONY: test
test: build
	helm repo update
	set -e && \
	for chart in $(FEATURE_CHARTS); do \
		make -C charts/$$chart test; \
	done
	make -C charts/k8s-monitoring test

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

.PHONY: clean
clean:
	rm -rf node_modules

####################################################################
#                           Linting                                #
####################################################################
.PHONY: lint lint-sh lint-md lint-txt lint-yml lint-alex lint-misspell lint-actionlint
lint: lint-sh lint-md lint-txt lint-yml lint-alex lint-misspell lint-actionlint

# Shell Linting for checking shell scripts
lint-sh lint-shell:
	@./scripts/lint-shell.sh || true

# Markdown Linting for checking markdown files
lint-md lint-markdown:
	@./scripts/lint-markdown.sh || true

# Text Linting for checking text files
lint-txt lint-text:
	@./scripts/lint-text.sh || true

# Yaml Linting for checking yaml files
lint-yml lint-yaml:
	@./scripts/lint-yaml.sh || true

# Alex Linting for checking insensitive language
lint-alex:
	@./scripts/lint-alex.sh || true

# Misspell Linting for checking common spelling mistakes
lint-misspell:
	@./scripts/lint-misspell.sh || true

# Actionlint Linting for checking GitHub Actions
lint-al lint-actionlint:
	@./scripts/lint-actionlint.sh || true
