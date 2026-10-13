HELM_VERSION ?=
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../../../scripts/helm-with-version $(HELM_VERSION)
endif

# The PodLogs CRD, from the Alloy chart that the Alloy Operator embeds.
ALLOY_CHART_VERSION = 1.13.0

.PHONY: clean all
clean:
	rm -f dependencies/podlogs-crd.yaml

all: dependencies/podlogs-crd.yaml

dependencies/podlogs-crd.yaml:
	$(HELM) template alloy alloy --repo https://grafana.github.io/helm-charts --version $(ALLOY_CHART_VERSION) --include-crds | yq 'select(.kind == "CustomResourceDefinition")' > $@
