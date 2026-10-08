HELM_VERSION ?= 4.1.4
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../../../scripts/helm-with-version $(HELM_VERSION)
export HELM_VERSION
export PATH := $(abspath $(dir $(word 1,$(HELM)))bin):$(PATH)
endif

SHELL := /bin/bash

.rendered/output.yaml: helmfile.yaml
	$(HELM) template k8smon ../../../.. -f <(yq '.releases[0].values[0]' $<) > $@

.PHONY: all
all: .rendered/output.yaml
