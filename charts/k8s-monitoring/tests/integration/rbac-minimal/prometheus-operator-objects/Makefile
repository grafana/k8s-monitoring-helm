HELM_VERSION ?=
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../../../scripts/helm-with-version $(HELM_VERSION)
endif

# Not shared with tests/integration/prometheus-operator-objects, because this test also needs PrometheusRules and AlertmanagerConfigs.
.PHONY: clean all
clean:
	rm -f dependencies/prometheus-operator-crds.yaml

all: dependencies/prometheus-operator-crds.yaml

dependencies/prometheus-operator-crds.yaml: dependencies/prometheus-operator-crds-values.yaml
	$(HELM) template prometheus-operator-crds prometheus-operator-crds --repo https://prometheus-community.github.io/helm-charts -f $< --include-crds | yq 'select(. != null)' > $@
