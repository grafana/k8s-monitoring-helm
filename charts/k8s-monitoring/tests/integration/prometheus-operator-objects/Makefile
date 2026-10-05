HELM_VERSION ?= 4.1.4
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../../scripts/helm-with-version $(HELM_VERSION)
HELM_BIN := $(shell ../../../../../scripts/helm-with-version which $(HELM_VERSION))
ifneq ($(HELM_BIN),)
export PATH := $(dir $(HELM_BIN)):$(PATH)
endif
endif

.PHONY: clean all
clean:
	rm -f dependencies/prometheus-operator-crds.yaml

all: dependencies/prometheus-operator-crds.yaml

dependencies/prometheus-operator-crds.yaml: dependencies/prometheus-operator-crds-values.yaml
	$(HELM) template prometheus-operator-crds prometheus-operator-crds --repo https://prometheus-community.github.io/helm-charts -f $< --include-crds | yq 'select(. != null)' > $@
