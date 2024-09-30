.PHONY: setup install lint lint-chart lint-config lint-configs lint-alloy lint-sh lint-md lint-txt lint-yml lint-ec lint-alex lint-misspell lint-actionlint test install-deps clean
SHELL := /bin/bash
UNAME := $(shell uname)

CT_CONFIGFILE ?= .github/configs/ct.yaml
LINT_CONFIGFILE ?= .github/configs/lintconf.yaml

####################################################################
#                   Installation / Setup                           #
####################################################################
setup install-deps:
ifeq ($(UNAME), Darwin)
	@./scripts/setup.sh
else
	echo "Not on MacOS, you'll have to just install things manually for now."
	exit 1
endif

install:
	yarn install

clean:
	rm -rf node_modules

####################################################################
#                           Linting                                #
####################################################################
lint: lint-chart lint-config lint-sh lint-md lint-txt lint-yml lint-ec lint-alex lint-misspell lint-actionlint

lint-chart:
	ct lint --debug --config "$(CT_CONFIGFILE)" --lint-conf "$(LINT_CONFIGFILE)" --check-version-increment=false

lint-config lint-configs lint-alloy:
	@./scripts/lint-alloy.sh $(METRICS_CONFIG_FILES) $(EVENTS_CONFIG_FILES) $(LOGS_CONFIG_FILES) --public-preview $(PROFILES_CONFIG_FILES)

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
