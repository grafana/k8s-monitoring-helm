.PHONY: clean
clean:
	rm -f deployments/test-variables.yaml deployments/grafana-cloud.yaml deployments/grafana-cloud-credentials.yaml

.PHONY: all
all: values.json deployments/test-variables.yaml deployments/grafana-cloud.yaml deployments/grafana-cloud-credentials.yaml

values.json: values.yaml
	yq eval --output-format json '. | del(.cluster.name)' values.yaml > $@

deployments/test-variables.yaml:
	echo "---" > $@
	kubectl create configmap test-variables \
		--from-literal=CLUSTER="$(shell yq eval '.cluster.name' values.yaml)-$$RANDOM_NUMBER" \
		--from-literal=RANDOM_NUMBER="$$RANDOM_NUMBER" \
		-o yaml --dry-run=client >> $@

deployments/grafana-cloud.yaml:
	echo "---" > $@
	kubectl create namespace monitoring --dry-run=client -o yaml >> $@
	echo "---" >> $@
	echo "# yamllint disable rule:line-length" >> $@
	kubectl create secret generic grafana-cloud \
		--namespace=monitoring \
		--from-literal=prometheus-host="https://prometheus-prod-13-prod-us-east-0.grafana.net" \
		--from-literal=prometheus-username="$$GRAFANA_CLOUD_METRICS_USERNAME" \
		--from-literal=prometheus-password="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
		--from-literal=loki-host="https://logs-prod-006.grafana.net" \
		--from-literal=loki-username="$$GRAFANA_CLOUD_LOGS_USERNAME" \
		--from-literal=loki-password="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
		--from-literal=tempo-host="https://tempo-prod-04-prod-us-east-0.grafana.net:443" \
		--from-literal=tempo-username="$$GRAFANA_CLOUD_TRACES_USERNAME" \
		--from-literal=tempo-password="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
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
