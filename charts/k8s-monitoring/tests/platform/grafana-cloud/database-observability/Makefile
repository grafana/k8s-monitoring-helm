.PHONY: clean
clean:
	rm -f grafana-cloud-credentials.yaml

.PHONY: all
all: grafana-cloud-credentials.yaml

grafana-cloud-credentials.yaml:
	echo "---" > $@
	echo "# yamllint disable rule:line-length" >> $@
	kubectl create secret generic grafana-cloud-credentials \
		--from-literal=metricsUser="$$GRAFANA_CLOUD_METRICS_USERNAME" \
		--from-literal=logsUser="$$GRAFANA_CLOUD_LOGS_USERNAME" \
		--from-literal=grafanaCloudAccessPolicyToken="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
		-o yaml --dry-run=client >> $@
	echo "---" >> $@
	echo "# yamllint disable rule:line-length" >> $@
	kubectl create secret generic grafana-cloud-credentials \
		--namespace=toolbox \
		--from-literal=PROMETHEUS_USER="$$GRAFANA_CLOUD_METRICS_USERNAME" \
		--from-literal=PROMETHEUS_PASS="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
		--from-literal=LOKI_USER="$$GRAFANA_CLOUD_LOGS_USERNAME" \
		--from-literal=LOKI_PASS="$$GRAFANA_CLOUD_RW_POLICY_TOKEN" \
		-o yaml --dry-run=client >> $@
