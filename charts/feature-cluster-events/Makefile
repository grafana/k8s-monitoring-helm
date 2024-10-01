HAS_HELM_DOCS := $(shell command -v helm-docs;)
HAS_HELM_UNITTEST := $(shell helm plugin list | grep unittest 2> /dev/null)

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

.PHONY: all
all: README.md Chart.lock values.schema.json

.PHONY: test
test: all
	helm lint .
ifdef HAS_HELM_UNITTEST
	helm unittest .
else
	docker run --rm --volume $(shell pwd):/apps helmunittest/helm-unittest .
endif
