HELM_VERSION ?=
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../scripts/helm-with-version $(HELM_VERSION)
endif

# Pinned manually and intentionally NOT tracked by Renovate: the tag is
# <helm-version>-<helm-unittest-version>, so an automated bump would also change
# the bundled Helm version. Update it deliberately.
HELM_UNITTEST_IMAGE_VERSION = 3.18.4-1.0.0

HAS_HELM_UNITTEST := $(shell $(HELM) plugin list | grep unittest 2> /dev/null)

K8S_MANIFEST_TAIL_VERSION := $(shell yq '.dependencies[] | select(.name == "k8s-manifest-tail") | .version' Chart.yaml)
KUBE_STATE_METRICS_VERSION := $(shell yq '.dependencies[] | select(.name == "kube-state-metrics") | .version' Chart.yaml)
NODE_EXPORTER_VERSION := $(shell yq '.dependencies[] | select(.name == "prometheus-node-exporter") | .version' Chart.yaml)
WINDOWS_EXPORTER_VERSION := $(shell yq '.dependencies[] | select(.name == "prometheus-windows-exporter") | .version' Chart.yaml)
GRAFANA_HELM_CHARTS_KEYRING := ../../../../keys/grafana-helm-charts-pubkey.gpg
PROMETHEUS_COMMUNITY_KEYRING := ../../../../keys/prometheus-community-pubkey.gpg

# OpenCost signs its chart with keyless cosign rather than a GPG provenance file,
# so it is verified against the signing workflow's certificate identity instead of
# a keyring. This chart depends on the signed OCI artifact directly (see Chart.yaml).
COSIGN ?= cosign
HAS_COSIGN := $(shell command -v $(COSIGN) 2> /dev/null)
# renovate: datasource=docker depName=ghcr.io/sigstore/cosign/cosign
COSIGN_IMAGE_VERSION = v3.1.3
OPENCOST_VERSION := $(shell yq '.dependencies[] | select(.name == "opencost") | .version' Chart.yaml)
OPENCOST_OCI_CHART := ghcr.io/opencost/charts/opencost
OPENCOST_COSIGN_IDENTITY := https://github.com/opencost/opencost-helm-chart/.github/workflows/publish.yml@refs/heads/main
OPENCOST_COSIGN_ISSUER := https://token.actions.githubusercontent.com

.SECONDEXPANSION:
README.md: values.yaml Chart.yaml $$(wildcard README.md.gotmpl)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-doc-generator --chart /chart > $@

Chart.lock: Chart.yaml | verify-signatures
	$(HELM) dependency update .
	@touch Chart.lock # Ensure the timestamp is updated

values.schema.json: values.yaml $$(wildcard schema-mods/*)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-schema-generator --chart /chart > $@

.PHONY: clean
clean:
	rm -f README.md values.schema.json $(ALLOW_LISTS)
	rm -rf $(VERIFY_CACHE)

.PHONY: build
build: README.md Chart.lock values.schema.json $(ALLOW_LISTS)

# Verifying a signed dependency is network-heavy (a helm pull + GPG check, or a cosign + Rekor lookup) but only
# meaningful when the pinned version or the trusted key changes. Each check records success in a stamp file under
# $(VERIFY_CACHE), so unchanged builds skip the network entirely.
#
# Stamps also expire: any older than VERIFY_TTL_MINUTES (24h) are pruned when this Makefile is parsed, so a long-lived
# working copy re-verifies at least daily. That bounds how long a cached success can outlive an upstream revocation - a
# distrusted cosign/Sigstore root, or a keyring update - before a local build re-checks it.
VERIFY_CACHE := .verified
VERIFY_TTL_MINUTES := 1440

# Drop expired stamps.
_prune := $(shell find $(VERIFY_CACHE) -type f ! -name .gitignore -mmin +$(VERIFY_TTL_MINUTES) -delete 2>/dev/null)

$(VERIFY_CACHE):
	@mkdir -p $@
	@printf '*\n' > $@/.gitignore   # self-ignore the cache for all clones/CI

$(VERIFY_CACHE)/k8s-manifest-tail-$(K8S_MANIFEST_TAIL_VERSION): $(GRAFANA_HELM_CHARTS_KEYRING) | $(VERIFY_CACHE)
	tmp="$$(mktemp -d)"; trap 'rm -rf "$$tmp"' EXIT; \
	$(HELM) pull k8s-manifest-tail \
		--repo https://grafana.github.io/helm-charts \
		--version $(K8S_MANIFEST_TAIL_VERSION) \
		--verify --keyring $(GRAFANA_HELM_CHARTS_KEYRING) \
		--destination "$$tmp"
	@touch $@

$(VERIFY_CACHE)/kube-state-metrics-$(KUBE_STATE_METRICS_VERSION): $(PROMETHEUS_COMMUNITY_KEYRING) | $(VERIFY_CACHE)
	tmp="$$(mktemp -d)"; trap 'rm -rf "$$tmp"' EXIT; \
	$(HELM) pull kube-state-metrics \
		--repo https://prometheus-community.github.io/helm-charts \
		--version $(KUBE_STATE_METRICS_VERSION) \
		--verify --keyring $(PROMETHEUS_COMMUNITY_KEYRING) \
		--destination "$$tmp"
	@touch $@

$(VERIFY_CACHE)/prometheus-node-exporter-$(NODE_EXPORTER_VERSION): $(PROMETHEUS_COMMUNITY_KEYRING) | $(VERIFY_CACHE)
	tmp="$$(mktemp -d)"; trap 'rm -rf "$$tmp"' EXIT; \
	$(HELM) pull prometheus-node-exporter \
		--repo https://prometheus-community.github.io/helm-charts \
		--version $(NODE_EXPORTER_VERSION) \
		--verify --keyring $(PROMETHEUS_COMMUNITY_KEYRING) \
		--destination "$$tmp"
	@touch $@

$(VERIFY_CACHE)/prometheus-windows-exporter-$(WINDOWS_EXPORTER_VERSION): $(PROMETHEUS_COMMUNITY_KEYRING) | $(VERIFY_CACHE)
	tmp="$$(mktemp -d)"; trap 'rm -rf "$$tmp"' EXIT; \
	$(HELM) pull prometheus-windows-exporter \
		--repo https://prometheus-community.github.io/helm-charts \
		--version $(WINDOWS_EXPORTER_VERSION) \
		--verify --keyring $(PROMETHEUS_COMMUNITY_KEYRING) \
		--destination "$$tmp"
	@touch $@

# Use a locally installed cosign when present, otherwise fall back to the cosign
# image (same pattern as helm-unittest/shellspec) so verification is always
# enforced - including in jobs that reach this via build-features but don't
# install cosign. The stamp is touched only after a successful verify.
$(VERIFY_CACHE)/opencost-$(OPENCOST_VERSION): | $(VERIFY_CACHE)
ifdef HAS_COSIGN
	$(COSIGN) verify $(OPENCOST_OCI_CHART):$(OPENCOST_VERSION) \
		--certificate-identity $(OPENCOST_COSIGN_IDENTITY) \
		--certificate-oidc-issuer $(OPENCOST_COSIGN_ISSUER) \
		> /dev/null
else
	docker run --rm ghcr.io/sigstore/cosign/cosign:$(COSIGN_IMAGE_VERSION) \
		verify $(OPENCOST_OCI_CHART):$(OPENCOST_VERSION) \
		--certificate-identity $(OPENCOST_COSIGN_IDENTITY) \
		--certificate-oidc-issuer $(OPENCOST_COSIGN_ISSUER) \
		> /dev/null
endif
	@touch $@

VERIFY_SIGNATURE_STAMPS := \
	$(VERIFY_CACHE)/k8s-manifest-tail-$(K8S_MANIFEST_TAIL_VERSION) \
	$(VERIFY_CACHE)/kube-state-metrics-$(KUBE_STATE_METRICS_VERSION) \
	$(VERIFY_CACHE)/prometheus-node-exporter-$(NODE_EXPORTER_VERSION) \
	$(VERIFY_CACHE)/prometheus-windows-exporter-$(WINDOWS_EXPORTER_VERSION) \
	$(VERIFY_CACHE)/opencost-$(OPENCOST_VERSION)

.PHONY: verify-signatures
verify-signatures: $(VERIFY_SIGNATURE_STAMPS) ## Verify the signatures of the signed chart dependencies

.PHONY: test
test: build
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	$(HELM) repo add kepler https://sustainable-computing-io.github.io/kepler-helm-chart
	$(HELM) repo add opencost https://opencost.github.io/opencost-helm-chart

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
