HAS_HELM_UNITTEST := $(shell helm plugin list | grep unittest 2> /dev/null)

.SECONDEXPANSION:
README.md: values.yaml Chart.yaml $$(wildcard README.md.gotmpl)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-doc-generator --chart /chart > $@

Chart.lock: Chart.yaml
	helm dependency update .
	@touch Chart.lock # Ensure the timestamp is updated

values.schema.json: values.yaml $$(wildcard schema-mods/*)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-schema-generator --chart /chart > $@

.PHONY: clean
clean:
	rm -f README.md values.schema.json

.PHONY: build
build: README.md Chart.lock values.schema.json

.PHONY: lint-shell
lint-shell:
	@if command -v shellcheck &> /dev/null; then \
		shellcheck collect-manifests.sh; \
	else \
		docker run --rm -v $(shell pwd):/src --workdir /src koalaman/shellcheck:stable --rcfile .shellcheckrc templates/script.sh; \
	fi

.PHONY: lint-helm
lint-helm:
	helm lint .
	ct lint --lint-conf ../../.lintconf.yaml --helm-dependency-extra-args=--skip-refresh --charts .

.PHONY: lint
lint: lint-shell lint-helm

.PHONY: test
test: build lint
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
