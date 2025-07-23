HAS_HELM_DOCS := $(shell command -v helm-docs;)
HAS_HELM_UNITTEST := $(shell helm plugin list | grep unittest 2> /dev/null)
ALLOW_LISTS := default-allow-lists/kube-state-metrics.yaml

.SECONDEXPANSION:
README.md: values.yaml Chart.yaml $$(wildcard README.md.gotmpl)
ifdef HAS_HELM_DOCS
	helm-docs
else
	docker run --rm --volume "$(shell pwd):/helm-docs" -u $(shell id -u) jnorwood/helm-docs:latest
endif

Chart.lock: Chart.yaml
	helm dependency update .
	@touch Chart.lock # Ensure the timestamp is updated

values.schema.json: values.yaml $$(wildcard schema-mods/*)
	../../../../scripts/schema-gen.sh .

default-allow-lists/%.yaml: ../../../../allowLists/%.yaml
	cp $< $@

.PHONY: clean
clean:
	rm -f README.md values.schema.json $(ALLOW_LISTS)

.PHONY: build
build: README.md Chart.lock values.schema.json $(ALLOW_LISTS)

.PHONY: test
test: build
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add kepler https://sustainable-computing-io.github.io/kepler-helm-chart
	helm repo add opencost https://opencost.github.io/opencost-helm-chart

	helm lint .
	ct lint --lint-conf ../../.lintconf.yaml --helm-dependency-extra-args=--skip-refresh --charts .
ifdef HAS_HELM_UNITTEST
	helm unittest .
else
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest:3.17.0-0.7.1 .
endif

.PHONY: update-test-snapshots
update-test-snapshots:
ifdef HAS_HELM_UNITTEST
	helm unittest . --update-snapshot
else
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest:3.17.0-0.7.1 . --update-snapshot
endif
