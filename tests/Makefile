.PHONY: test lint-config clean-outputs generate-outputs regenerate-outputs
SHELL := /bin/bash

ifndef HELM_CHART_PATH
override HELM_CHART_PATH = ../charts/k8s-monitoring
endif

INPUT_FILES = $(wildcard ./*/values.yaml)
OUTPUT_FILES = $(subst values.yaml,output.yaml,$(INPUT_FILES))

lint-config: $(OUTPUT_FILES)
	for file in $^; \
	do \
		echo "Linting Agent config in $${file}..."; \
		AGENT_MODE=flow grafana-agent fmt <(yq -r 'select(.metadata.name=="grafana-agent-config") | .data["config.river"]' $$file) > /dev/null; \
	done

test: test-runner.sh lint-config
	HELM_CHART_PATH=$(HELM_CHART_PATH) ./test-runner.sh --show-diffs

%/output.yaml: %/values.yaml
	helm template k8smon $(HELM_CHART_PATH) -f $< > $@

clean-outputs:
	rm -f $(OUTPUT_FILES)

generate-outputs: $(OUTPUT_FILES)

regenerate-outputs: clean-outputs generate-outputs