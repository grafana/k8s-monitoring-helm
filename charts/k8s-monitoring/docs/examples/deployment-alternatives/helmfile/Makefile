HELM_VERSION ?= 4.1.4
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../../../scripts/helm-with-version $(HELM_VERSION)
HELM_BIN := $(shell ../../../../../../scripts/helm-with-version which $(HELM_VERSION))
ifneq ($(HELM_BIN),)
export PATH := $(dir $(HELM_BIN)):$(PATH)
endif
endif

SHELL := /bin/bash

.rendered/output.yaml: helmfile.yaml
	$(HELM) template k8smon ../../../.. -f <(yq '.releases[0].values[0]' $<) > $@

.PHONY: all
all: .rendered/output.yaml
