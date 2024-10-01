SHELL := /bin/bash
UNAME := $(shell uname)

FEATURE_CHARTS = $(shell ls charts | grep -v k8s-monitoring)

.PHONY: build
build:
	set -e && \
	for chart in $(FEATURE_CHARTS); do \
		make -C charts/$$chart build; \
	done
	#make -C charts/k8s-monitoring build

.PHONY: test
test: build
	set -e && \
	for chart in $(FEATURE_CHARTS); do \
		make -C charts/$$chart test; \
	done
	#make -C charts/k8s-monitoring test

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
.PHONY: lint lint-chart lint-sh lint-md lint-txt lint-yml lint-ec lint-alex lint-misspell lint-actionlint
lint: lint-chart lint-sh lint-md lint-txt lint-yml lint-ec lint-alex lint-misspell lint-actionlint

lint-chart:
	ct lint --debug --config .github/configs/ct.yaml --lint-conf .github/configs/lintconf.yaml --check-version-increment=false

# Shell Linting
lint-sh lint-shell:
	@./scripts/lint-shell.sh || true

# Markdown Linting
lint-md lint-markdown:
	@./scripts/lint-markdown.sh || true

# Text Linting
lint-txt lint-text:
	@./scripts/lint-text.sh || true

# Yaml Linting
lint-yml lint-yaml:
	@./scripts/lint-yaml.sh || true

# Editorconfig Linting
lint-ec lint-editorconfig:
	@./scripts/lint-editorconfig.sh || true

# Alex Linting
lint-alex:
	@./scripts/lint-alex.sh || true

# Misspell Linting
lint-misspell:
	@./scripts/lint-misspell.sh || true

# Actionlint Linting
lint-al lint-actionlint:
	@./scripts/lint-actionlint.sh || true
