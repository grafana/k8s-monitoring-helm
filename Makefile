.PHONY: test lint-chart lint-config clean-example-outputs generate-example-outputs regenerate-example-outputs
SHELL := /bin/bash
UNAME := $(shell uname)

CHART_FILES = $(shell find charts/k8s-monitoring -type f)
INPUT_FILES = $(wildcard examples/*/values.yaml)
OUTPUT_FILES = $(subst values.yaml,output.yaml,$(INPUT_FILES))
METRICS_CONFIG_FILES = $(subst values.yaml,metrics.alloy,$(INPUT_FILES))
EVENTS_CONFIG_FILES = $(subst values.yaml,events.alloy,$(INPUT_FILES))
LOGS_CONFIG_FILES = $(subst values.yaml,logs.alloy,$(INPUT_FILES))
PROFILES_CONFIG_FILES = $(subst values.yaml,profiles.alloy,$(INPUT_FILES))

CT_CONFIGFILE ?= .github/configs/ct.yaml
LINT_CONFIGFILE ?= .github/configs/lintconf.yaml

lint-chart:
	ct lint --debug --config "$(CT_CONFIGFILE)" --lint-conf "$(LINT_CONFIGFILE)" --check-version-increment=false

lint-config: scripts/lint-configs.sh
	./scripts/lint-configs.sh $(METRICS_CONFIG_FILES) $(EVENTS_CONFIG_FILES) $(LOGS_CONFIG_FILES) --public-preview $(PROFILES_CONFIG_FILES)

test: scripts/test-runner.sh lint-chart lint-config
	./scripts/test-runner.sh --show-diffs
	cd tests; shellspec

install-deps:
ifeq ($(UNAME), Darwin)
	brew install chart-testing grafana/grafana/alloy helm norwoodj/tap/helm-docs kind shellspec yamllint yq
else
	echo "Not on MacOS, you'll have to just install things manually for now."
	exit 1
endif

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

clean:
	rm -f $(OUTPUT_FILES) $(METRIC_CONFIG_FILES) $(EVENT_CONFIG_FILES) $(LOG_CONFIG_FILES)

generate-example-outputs: $(OUTPUT_FILES) $(METRICS_CONFIG_FILES) $(EVENTS_CONFIG_FILES) $(LOGS_CONFIG_FILES) $(PROFILES_CONFIG_FILES)

regenerate-example-outputs: clean generate-example-outputs
