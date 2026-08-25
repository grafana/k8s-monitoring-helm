# Instrumentation Hub e2e — standard tier.
#
# `make all` (run before helm-test): generate Grafana Cloud credentials, provision
# the IHUB pipelines in Fleet Management for this cluster (what the onboarding UI
# does), and derive the expected Alloy components FM holds (for the in-cluster
# comparison). `make teardown` removes the per-cluster FM pipelines and is meant
# to run in an always() CI step. Helpers are bash scripts under ../scripts.
# Append a random suffix, written to .random here and reused by helm-test's getClusterName,
# so provision/teardown and the cluster it creates share one name.
CLUSTER := $(shell yq eval '.cluster.name' test-plan.yaml)-$(shell [ -f .random ] || shuf -i 100000-999999 -n 1 > .random; cat .random)
SCRIPTS := ../scripts

export IHUB_APP_NAMESPACE := default
export GRAFANA_CLOUD_STACK := helmchart
export GRAFANA_SERVER := https://$(GRAFANA_CLOUD_STACK).grafana.net

HELM_TEST ?= helm-test

.PHONY: run-test run-test-direnv
run-test:
	$(MAKE) clean all
	$(HELM_TEST) .

run-test-direnv:
	direnv allow .
	direnv exec . $(MAKE) run-test

.PHONY: all clean provision teardown provision-direnv expected-components-direnv teardown-direnv

all: grafana-cloud-credentials.yaml provision expected-components.yaml

clean:
	rm -f grafana-cloud-credentials.yaml expected-components.yaml

grafana-cloud-credentials.yaml:
	echo "---" > $@
	echo "# yamllint disable rule:line-length" >> $@
	kubectl create secret generic grafana-cloud-credentials \
		--from-literal=GRAFANA_CLOUD_FLEET_MGMT_USER="$$GRAFANA_CLOUD_FLEET_MGMT_USER" \
		--from-literal=GRAFANA_CLOUD_FLEET_MGMT_TOKEN="$$GRAFANA_CLOUD_FLEET_MGMT_TOKEN" \
		-o yaml --dry-run=client >> $@
	echo "---" >> $@
	echo "# yamllint disable rule:line-length" >> $@
	kubectl create secret generic grafana-cloud-credentials \
		--namespace=toolbox \
		--from-literal=PROMETHEUS_USER="$$GRAFANA_CLOUD_METRICS_USERNAME" \
		--from-literal=PROMETHEUS_PASS="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
		-o yaml --dry-run=client >> $@

# Provision families 1+2 (survey + k8s monitoring) in Fleet Management. Always runs.
provision:
	$(SCRIPTS)/provision.sh "$(CLUSTER)"

provision-direnv:
	direnv allow .
	direnv exec . $(MAKE) provision

# Derive the expected components from the FM pipelines just provisioned.
expected-components.yaml: provision
	$(SCRIPTS)/derive-expected.sh "$(CLUSTER)" "$@" toolbox

expected-components-direnv:
	direnv allow .
	direnv exec . $(MAKE) expected-components.yaml

# Remove the per-cluster FM pipelines this run created (run in an always() step).
teardown:
	$(SCRIPTS)/teardown.sh "$(CLUSTER)"

teardown-direnv:
	direnv allow .
	direnv exec . $(MAKE) teardown
	kind delete cluster --name $(CLUSTER)
	rm -f .random
