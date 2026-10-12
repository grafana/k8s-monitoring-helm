HELM_VERSION_FILE := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../../../../.helm-version)
HELM_VERSION ?= $(shell cat $(HELM_VERSION_FILE))
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../../scripts/helm-with-version $(HELM_VERSION)
export HELM_VERSION
export PATH := $(abspath $(dir $(word 1,$(HELM)))bin):$(PATH)
endif

.PHONY: clean all
clean:
	rm -f dependencies/prometheus-operator-crds.yaml

all: dependencies/prometheus-operator-crds.yaml

dependencies/prometheus-operator-crds.yaml: dependencies/prometheus-operator-crds-values.yaml
	$(HELM) template prometheus-operator-crds prometheus-operator-crds --repo https://prometheus-community.github.io/helm-charts -f $< --include-crds | yq 'select(. != null)' > $@
