HELM_VERSION ?=
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../scripts/helm-with-version $(HELM_VERSION)
endif

# renovate: datasource=docker depName=ghcr.io/grafana/helm-chart-toolbox-doc-generator
DOC_GENERATOR_IMAGE_VERSION = 0.2.4
# renovate: datasource=docker depName=ghcr.io/grafana/helm-chart-toolbox-schema-generator
SCHEMA_GENERATOR_IMAGE_VERSION = 0.2.4

HELM_UNITTEST_IMAGE_VERSION = 3.18.4-1.0.0

HAS_HELM_UNITTEST := $(shell $(HELM) plugin list | grep unittest 2> /dev/null)
ALLOW_LISTS := default-allow-lists/kepler.yaml \
	default-allow-lists/node-exporter.yaml \
	default-allow-lists/node-exporter-integration.yaml \
	default-allow-lists/windows-exporter.yaml

.SECONDEXPANSION:
README.md: values.yaml Chart.yaml $$(wildcard README.md.gotmpl)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-doc-generator:$(DOC_GENERATOR_IMAGE_VERSION) --chart /chart > $@

Chart.lock: Chart.yaml
	$(HELM) dependency update .
	@touch Chart.lock # Ensure the timestamp is updated

values.schema.json: values.yaml $$(wildcard schema-mods/*)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-schema-generator:$(SCHEMA_GENERATOR_IMAGE_VERSION) --chart /chart > $@

default-allow-lists/%.yaml: ../../../../allowLists/%.yaml
	mkdir -p $(shell dirname $@)
	cp $< $@

.PHONY: clean
clean:
	rm -f README.md values.schema.json $(ALLOW_LISTS)

.PHONY: build
build: README.md Chart.lock values.schema.json $(ALLOW_LISTS)

.PHONY: test
test: build
	$(HELM) lint .
	ct lint --lint-conf ../../.lintconf.yaml --helm-dependency-extra-args=--skip-refresh --charts .
ifdef HAS_HELM_UNITTEST
	$(HELM) unittest .
else
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest:$(HELM_UNITTEST_IMAGE_VERSION) .
endif

.PHONY: update-test-snapshots
update-test-snapshots:
ifdef HAS_HELM_UNITTEST
	$(HELM) unittest . --update-snapshot
else
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest:$(HELM_UNITTEST_IMAGE_VERSION) . --update-snapshot
endif
