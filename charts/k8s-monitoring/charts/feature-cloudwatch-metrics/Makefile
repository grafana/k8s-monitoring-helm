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

# Pinned manually and intentionally NOT tracked by Renovate: the tag is
# <helm-version>-<helm-unittest-version>, so an automated bump would also change
# the bundled Helm version. Update it deliberately.
HELM_UNITTEST_IMAGE_VERSION = 3.18.4-1.0.0

HAS_HELM_UNITTEST := $(shell $(HELM) plugin list | grep unittest 2> /dev/null)

.SECONDEXPANSION:
# The chart's own values only hold `global` and `instances`, so the generated values section is appended with the
# instance settings from docs/instance.md. That keeps instance-defaults.yaml the only source for those tables.
README.md: values.yaml Chart.yaml docs/instance.md $$(wildcard README.md.gotmpl)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-doc-generator:$(DOC_GENERATOR_IMAGE_VERSION) --chart /chart > $@
	printf '\n### Instance Settings\n\nThese are the settings for each entry in `instances`. See the [instance settings](./docs/instance.md) for how the jobs,\nregions, and authentication settings fit together, and for the options on each job and metric.\n' >> $@
	sed -n '/^## Values$$/,$$p' docs/instance.md | sed '1d;s/^### /#### /' >> $@

# The settings for each entry in `instances` live in their own values file, so they get their own generated doc.
docs/instance.md: instance-defaults.yaml $$(wildcard docs/.doc_templates/instance.gotmpl)
	docker run --platform linux/amd64 --rm --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-doc-generator:$(DOC_GENERATOR_IMAGE_VERSION) --file /chart/$< --template /chart/docs/.doc_templates/instance.gotmpl > $@

Chart.lock: Chart.yaml
	$(HELM) dependency update .
	@touch Chart.lock # Ensure the timestamp is updated

values.schema.json: values.yaml $$(wildcard schema-mods/*)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-schema-generator:$(SCHEMA_GENERATOR_IMAGE_VERSION) --chart /chart > $@

.PHONY: clean
clean:
	rm -f README.md values.schema.json docs/instance.md

.PHONY: build
build: README.md docs/instance.md Chart.lock values.schema.json

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
