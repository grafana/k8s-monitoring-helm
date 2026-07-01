.PHONY: clean
clean:
	rm -f grafana-cloud-credentials.yaml

.PHONY: all
all: grafana-cloud-credentials.yaml

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
