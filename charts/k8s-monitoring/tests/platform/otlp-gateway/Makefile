.PHONY: check
check: ;

.PHONY: clean
clean:
	rm -f deployments/test-variables.yaml deployments/grafana-cloud-credentials.yaml

.PHONY: all
all: deployments/test-variables.yaml deployments/grafana-cloud-credentials.yaml

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
  		--from-literal=OTLP_GATEWAY_USER="$$GRAFANA_CLOUD_OTLP_USERNAME" \
  		--from-literal=OTLP_GATEWAY_PASS="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
  		--from-literal=PROMETHEUS_USER="$$GRAFANA_CLOUD_METRICS_USERNAME" \
  		--from-literal=PROMETHEUS_PASS="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
  		--from-literal=LOKI_USER="$$GRAFANA_CLOUD_LOGS_USERNAME" \
  		--from-literal=LOKI_PASS="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
		-o yaml --dry-run=client >> $@

.PHONY: run-test
run-test:
	../../../../../scripts/run-cluster-test.sh .
