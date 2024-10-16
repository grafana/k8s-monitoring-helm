HAS_HELM_DOCS := $(shell command -v helm-docs;)
HAS_HELM_UNITTEST := $(shell helm plugin list | grep unittest 2> /dev/null)
UPDATECLI_FILES := $(shell yq -e '.dependencies[] | select(.repository == "http*") | ".updatecli-" + .name + ".yaml"' Chart.yaml 2>/dev/null | sort | uniq)

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
	../../scripts/schema-gen.sh .

.updatecli-%.yaml: Chart.yaml
	../../scripts/charts-to-updatecli.sh Chart.yaml

.PHONY: clean
clean:
	rm -f README.md values.schema.json $(UPDATECLI_FILES)

.PHONY: build
build: README.md Chart.lock values.schema.json $(UPDATECLI_FILES)

.PHONY: test
test: build
	helm lint .
	ct lint --lint-conf ../../.configs/lintconf.yaml --helm-dependency-extra-args=--skip-refresh --charts .
ifdef HAS_HELM_UNITTEST
	helm unittest .
else
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest .
endif
