HAS_HELM_UNITTEST := $(shell helm plugin list | grep unittest 2> /dev/null)

KUBE_STATE_METRICS_VERSION := $(shell yq '.dependencies[] | select(.name == "kube-state-metrics") | .version' Chart.yaml)
NODE_EXPORTER_VERSION := $(shell yq '.dependencies[] | select(.name == "prometheus-node-exporter") | .version' Chart.yaml)
WINDOWS_EXPORTER_VERSION := $(shell yq '.dependencies[] | select(.name == "prometheus-windows-exporter") | .version' Chart.yaml)
PROMETHEUS_COMMUNITY_KEYRING := ../../../../keys/prometheus-community-pubkey.gpg

# OpenCost signs its chart with keyless cosign rather than a GPG provenance file,
# so it is verified against the signing workflow's certificate identity instead of
# a keyring. This chart depends on the signed OCI artifact directly (see Chart.yaml).
COSIGN ?= cosign
OPENCOST_VERSION := $(shell yq '.dependencies[] | select(.name == "opencost") | .version' Chart.yaml)
OPENCOST_OCI_CHART := ghcr.io/opencost/charts/opencost
OPENCOST_COSIGN_IDENTITY := https://github.com/opencost/opencost-helm-chart/.github/workflows/publish.yml@refs/heads/main
OPENCOST_COSIGN_ISSUER := https://token.actions.githubusercontent.com

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

.PHONY: verify-signatures
verify-signatures: ## Verify the signatures of the signed chart dependencies
	helm pull kube-state-metrics \
		--repo https://prometheus-community.github.io/helm-charts \
		--version $(KUBE_STATE_METRICS_VERSION) \
		--verify --keyring $(PROMETHEUS_COMMUNITY_KEYRING) \
		--destination "$$(mktemp -d)"
	helm pull prometheus-node-exporter \
		--repo https://prometheus-community.github.io/helm-charts \
		--version $(NODE_EXPORTER_VERSION) \
		--verify --keyring $(PROMETHEUS_COMMUNITY_KEYRING) \
		--destination "$$(mktemp -d)"
	helm pull prometheus-windows-exporter \
		--repo https://prometheus-community.github.io/helm-charts \
		--version $(WINDOWS_EXPORTER_VERSION) \
		--verify --keyring $(PROMETHEUS_COMMUNITY_KEYRING) \
		--destination "$$(mktemp -d)"
	$(COSIGN) verify $(OPENCOST_OCI_CHART):$(OPENCOST_VERSION) \
		--certificate-identity $(OPENCOST_COSIGN_IDENTITY) \
		--certificate-oidc-issuer $(OPENCOST_COSIGN_ISSUER) \
		> /dev/null

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
