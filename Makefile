.PHONY: test lint-chart lint-config clean-example-outputs generate-example-outputs regenerate-example-outputs
SHELL := /bin/bash

CHART_FILES = $(shell find charts/k8s-monitoring -type f)
INPUT_FILES = $(wildcard examples/*/values.yaml)
OUTPUT_FILES = $(subst values.yaml,output.yaml,$(INPUT_FILES))
METRIC_CONFIG_FILES = $(subst values.yaml,metrics.river,$(INPUT_FILES))
LOG_CONFIG_FILES = $(subst values.yaml,logs.river,$(INPUT_FILES))

CT_CONFIGFILE ?= .github/configs/ct.yaml
LINT_CONFIGFILE ?= .github/configs/lintconf.yaml

lint-chart:
	ct lint --debug --config "$(CT_CONFIGFILE)" --lint-conf "$(LINT_CONFIGFILE)" --check-version-increment=false

lint-config: scripts/lint-configs.sh
	./scripts/lint-configs.sh $(METRIC_CONFIG_FILES) $(LOG_CONFIG_FILES)

test: scripts/test-runner.sh lint-chart lint-config
	./scripts/test-runner.sh --show-diffs
	cd tests; shellspec

install-deps: scripts/install-deps.sh
	./scripts/install-deps.sh

%/output.yaml: %/values.yaml $(CHART_FILES)
	helm template k8smon charts/k8s-monitoring -f $< > $@

%/metrics.river: %/output.yaml
	yq -r "select(.metadata.name==\"k8smon-grafana-agent\") | .data[\"config.river\"] | select( . != null )" $< > $@

%/logs.river: %/output.yaml
	yq -r "select(.metadata.name==\"k8smon-grafana-agent-logs\") | .data[\"config.river\"] | select( . != null )" $< > $@

clean:
	rm -f $(OUTPUT_FILES) $(METRIC_CONFIG_FILES) $(LOG_CONFIG_FILES)

generate-example-outputs: $(OUTPUT_FILES) $(METRIC_CONFIG_FILES) $(LOG_CONFIG_FILES)

regenerate-example-outputs: clean generate-example-outputs
