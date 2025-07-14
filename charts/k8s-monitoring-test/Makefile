HAS_HELM_UNITTEST := $(shell helm plugin list | grep unittest 2> /dev/null)

.SECONDEXPANSION:
README.md: values.yaml Chart.yaml $$(wildcard README.md.gotmpl)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-doc-generator --chart /chart > $@

Chart.lock: Chart.yaml
	helm dependency update .
	@touch Chart.lock # Ensure the timestamp is updated

values.schema.json: values.yaml $$(wildcard schema-mods/*)
	../../scripts/schema-gen.sh .

build-query-test-image: query-test/Dockerfile query-test/query-test.sh
	docker build --platform linux/amd64 --tag ghcr.io/grafana/query-test:$(shell yq -r '.version' Chart.yaml) query-test

push-query-test-image:
	docker push ghcr.io/grafana/query-test:$(shell yq -r '.version' Chart.yaml)

.PHONY: clean
clean:
	rm -f README.md values.schema.json

.PHONY: build
build: README.md Chart.lock values.schema.json

.PHONY: test
test: build
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm lint .
	ct lint --lint-conf .lintconf.yaml --helm-dependency-extra-args=--skip-refresh --charts .
ifdef HAS_HELM_UNITTEST
	helm unittest .
else
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest:3.17.0-0.7.1 .
endif
