HAS_HELM_UNITTEST := $(shell helm plugin list | grep unittest 2> /dev/null)
ALLOW_LISTS := default-allow-lists/cadvisor.yaml \
	default-allow-lists/kepler.yaml \
	default-allow-lists/kube-state-metrics.yaml \
	default-allow-lists/kubelet.yaml \
	default-allow-lists/kubelet_probes.yaml \
	default-allow-lists/kubelet_resource.yaml \
	default-allow-lists/node-exporter.yaml \
	default-allow-lists/node-exporter-integration.yaml \
	default-allow-lists/opencost.yaml \
	default-allow-lists/windows-exporter.yaml

.SECONDEXPANSION:
README.md: values.yaml Chart.yaml $$(wildcard README.md.gotmpl)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-doc-generator --chart /chart > $@

Chart.lock: Chart.yaml
	helm dependency update .
	@touch Chart.lock # Ensure the timestamp is updated

values.schema.json: values.yaml $$(wildcard schema-mods/*)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-schema-generator --chart /chart > $@

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
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest:3.18.4-1.0.0 .
endif

.PHONY: update-test-snapshots
update-test-snapshots:
ifdef HAS_HELM_UNITTEST
	helm unittest . --update-snapshot
else
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest:3.18.4-1.0.0 . --update-snapshot
endif
