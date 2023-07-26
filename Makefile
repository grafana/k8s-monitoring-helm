.PHONY: test lint-chart lint-config clean-example-outputs generate-example-outputs regenerate-example-outputs
SHELL := /bin/bash

INPUT_FILES = $(wildcard examples/*/values.yaml)
OUTPUT_FILES = $(subst values.yaml,output.yaml,$(INPUT_FILES))

CT_CONFIGFILE ?= .github/configs/ct.yaml
LINT_CONFIGFILE ?= .github/configs/lintconf.yaml

lint-chart:
ifeq ($(GITHUB_HEAD_REF),main)
	ct lint --debug --config "$(CT_CONFIGFILE)" --lint-conf "$(LINT_CONFIGFILE)"
else
	ct lint --debug --config "$(CT_CONFIGFILE)" --lint-conf "$(LINT_CONFIGFILE)" --check-version-increment=false
endif

lint-config: scripts/lint-configs.sh
	./scripts/lint-configs.sh $(OUTPUT_FILES)

test: scripts/test-runner.sh lint-chart lint-config
	./scripts/test-runner.sh --show-diffs

%/output.yaml: %/values.yaml
	helm template k8smon charts/k8s-monitoring -f $< > $@

clean-example-outputs:
	rm -f $(OUTPUT_FILES)

generate-example-outputs: $(OUTPUT_FILES)

regenerate-example-outputs: clean-example-outputs generate-example-outputs
