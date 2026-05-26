HELM_VERSION ?=
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../../scripts/helm-with-version $(HELM_VERSION)
endif

SHELL := /bin/bash

.rendered/output.yaml: helmfile.yaml
	$(HELM) template k8smon ../../../.. -f <(yq '.releases[0].values[0]' $<) > $@

.PHONY: all
all: .rendered/output.yaml
