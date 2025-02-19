.PHONY: all clean run-test console
all: deployments/okderators.yaml deployments/test-variables.yaml deployments/grafana-cloud-credentials.yaml flux-manifest.yaml
clean:
	rm -f deployments/okderators.yaml deployments/test-variables.yaml deployments/grafana-cloud-credentials.yaml flux-manifest.yaml

deployments/okderators.yaml:
	echo "---" > $@
	curl https://raw.githubusercontent.com/okd-project/okderators-catalog-index/refs/heads/main/install/okderators.catalogsource.yml >> $@

deployments/test-variables.yaml:
	echo "---" > $@
	kubectl create configmap test-variables \
		--from-literal=CLUSTER="$(shell yq eval '.cluster.name' values.yaml)-$$RANDOM_NUMBER" \
		--from-literal=RANDOM_NUMBER="$$RANDOM_NUMBER" \
		-o yaml --dry-run=client >> $@

deployments/grafana-cloud-credentials.yaml:
	echo "---" > $@
	echo "# yamllint disable rule:line-length" >> $@
	kubectl create secret generic grafana-cloud-credentials \
  		--from-literal=PROMETHEUS_USER="$$GRAFANA_CLOUD_METRICS_USERNAME" \
  		--from-literal=PROMETHEUS_PASS="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
  		--from-literal=LOKI_USER="$$GRAFANA_CLOUD_LOGS_USERNAME" \
  		--from-literal=LOKI_PASS="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
		-o yaml --dry-run=client >> $@

flux-manifest.yaml:
	flux install \
		--components source-controller,helm-controller \
		--export > flux-temp.yaml
	echo "---" >> flux-temp.yaml
	curl https://raw.githubusercontent.com/fluxcd/flux2/main/manifests/openshift/scc.yaml >> flux-temp.yaml
	kustomize build . > $@
	rm flux-temp.yaml

run-test:
	../../../../../scripts/run-cluster-test.sh .

CLUSTER_NAME_PREFIX := $(shell yq eval '.cluster.name' values.yaml)
CLUSTER_NAME := $(CLUSTER_NAME_PREFIX)-$(shell echo $$RANDOM_NUMBER)
console:
	@echo "URL:      $(shell grep --color=never 'Access the OpenShift web-console here' "$(CLUSTER_NAME)-installer-files/.openshift_install.log" | sed -e 's/.*Access the OpenShift web-console here: \(https:.*\)"/\1/')"
	@echo "Username: $(shell grep --color=never 'Login to the console with user:' "$(CLUSTER_NAME)-installer-files/.openshift_install.log" | sed -e 's/.*Login to the console with user: \\"\([-a-zA-Z0-9]*\)\\", and password: \\"\([-a-zA-Z0-9]*\)\\""/\1/')"
	@echo "Password: $(shell grep --color=never 'Login to the console with user:' "$(CLUSTER_NAME)-installer-files/.openshift_install.log" | sed -e 's/.*Login to the console with user: \\"\([-a-zA-Z0-9]*\)\\", and password: \\"\([-a-zA-Z0-9]*\)\\""/\2/')"
