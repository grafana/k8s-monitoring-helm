.PHONY: setup install lint lint-chart lint-config lint-configs lint-alloy lint-sh lint-md lint-txt lint-yml lint-ec lint-alex lint-misspell lint-actionlint test install-deps clean generate-example-outputs regenerate-example-outputs
SHELL := /bin/bash
UNAME := $(shell uname)

CHART_FILES = $(shell find charts/k8s-monitoring -type f)
INPUT_FILES = $(wildcard examples/*/values.yaml)
OUTPUT_FILES = $(subst values.yaml,output.yaml,$(INPUT_FILES))
METRICS_CONFIG_FILES = $(subst values.yaml,metrics.alloy,$(INPUT_FILES))
EVENTS_CONFIG_FILES = $(subst values.yaml,events.alloy,$(INPUT_FILES))
LOGS_CONFIG_FILES = $(subst values.yaml,logs.alloy,$(INPUT_FILES))
PROFILES_CONFIG_FILES = $(subst values.yaml,profiles.alloy,$(INPUT_FILES))
RULES_CONFIG_FILES = $(subst values.yaml,rules.alloy,$(INPUT_FILES))

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
	rm -rf node_modules $(OUTPUT_FILES) $(METRIC_CONFIG_FILES) $(EVENT_CONFIG_FILES) $(LOG_CONFIG_FILES)

####################################################################
#                           Linting                                #
####################################################################
lint: lint-chart lint-config lint-sh lint-md lint-txt lint-yml lint-ec lint-alex lint-misspell lint-actionlint

lint-chart:
	ct lint --debug --config "$(CT_CONFIGFILE)" --lint-conf "$(LINT_CONFIGFILE)" --check-version-increment=false

lint-config lint-configs lint-alloy:
	@./scripts/lint-alloy.sh $(METRICS_CONFIG_FILES) $(EVENTS_CONFIG_FILES) $(LOGS_CONFIG_FILES) $(RULES_CONFIG_FILES) --public-preview $(PROFILES_CONFIG_FILES)

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

####################################################################
#                           Testing                                #
####################################################################
test: scripts/test-runner.sh lint-chart lint-config
	./scripts/test-runner.sh --show-diffs
	cd tests; shellspec

####################################################################
#                           Outputs                                #
####################################################################
%/output.yaml: %/values.yaml $(CHART_FILES)
	helm template k8smon charts/k8s-monitoring -f $< > $@

%/metrics.alloy: %/output.yaml
	yq -r "select(.metadata.name==\"k8smon-alloy\") | .data[\"config.alloy\"] | select( . != null )" $< > $@

%/events.alloy: %/output.yaml
	yq -r "select(.metadata.name==\"k8smon-alloy-events\") | .data[\"config.alloy\"] | select( . != null )" $< > $@

%/logs.alloy: %/output.yaml
	yq -r "select(.metadata.name==\"k8smon-alloy-logs\") | .data[\"config.alloy\"] | select( . != null )" $< > $@

%/profiles.alloy: %/output.yaml
	yq -r "select(.metadata.name==\"k8smon-alloy-profiles\") | .data[\"config.alloy\"] | select( . != null )" $< > $@

%/rules.alloy: %/output.yaml
	yq -r "select(.metadata.name==\"k8smon-alloy-rules\") | .data[\"config.alloy\"] | select( . != null )" $< > $@

generate-example-outputs: $(OUTPUT_FILES) $(METRICS_CONFIG_FILES) $(EVENTS_CONFIG_FILES) $(LOGS_CONFIG_FILES) $(PROFILES_CONFIG_FILES) $(RULES_CONFIG_FILES)

regenerate-example-outputs: clean generate-example-outputs
