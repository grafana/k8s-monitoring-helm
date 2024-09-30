SHELL := /bin/bash

CHART_TEMPLATE_FILES = $(shell find templates -name "*.tpl")
CHART_YAML_FILES = $(shell find templates -name "*.yaml")

values.schema.json: values.yaml schema-mods/enums-and-types.json schema-mods/required-values.json
	docker run -it --rm --platform linux/amd64 -v "$(shell pwd):/chart" --entrypoint sh alpine/helm \
		--command -c 'helm plugin install https://github.com/karuppiah7890/helm-schema-gen.git && \
			helm schema-gen /chart/values.yaml > /chart/values.schema.generated.json'

	jq --indent 4 -s '.[0] * .[1] * .[2]' \
		<(jq --indent 4 \
			'del(.properties["alloy"].properties.alloy) \
			| del(.properties["alloy"].properties.controller) \
			| del(.properties["alloy"].properties.crds) \
			| del(.properties["alloy-events"].properties.alloy) \
			| del(.properties["alloy-events"].properties.controller) \
			| del(.properties["alloy-events"].properties.crds) \
			| del(.properties["alloy-logs"].properties.alloy) \
			| del(.properties["alloy-logs"].properties.controller) \
			| del(.properties["alloy-logs"].properties.crds) \
			| del(.properties["alloy-profiles"].properties.alloy) \
			| del(.properties["alloy-profiles"].properties.controller) \
			| del(.properties["alloy-profiles"].properties.crds) \
			| del(.properties["kepler"].properties.canMount) \
			| del(.properties["beyla"].properties.config) \
			| del(.properties["kube-state-metrics"].properties.autosharding) \
			| del(.properties["kube-state-metrics"].properties.nodeSelector) \
			| del(.properties["kube-state-metrics"].properties.prometheusScrape) \
			| del(.properties["kube-state-metrics"].properties.releaseLabel) \
			| del(.properties["kube-state-metrics"].properties.updateStrategy) \
			| del(.properties["prometheus-node-exporter"].properties.nodeSelector) \
			| del(.properties["prometheus-node-exporter"].properties.podAnnotations) \
			| del(.properties["prometheus-node-exporter"].properties.releaseLabel) \
			| del(.properties["prometheus-node-exporter"].properties.service) \
			| del(.properties["prometheus-windows-exporter"].properties.config) \
			| del(.properties["prometheus-windows-exporter"].properties.podAnnotations) \
			| del(.properties["prometheus-windows-exporter"].properties.releaseLabel) \
			| del(.properties.logs.properties.pod_logs.properties.labels.properties) \
			| del(.properties.opencost.properties.opencost)' values.schema.generated.json) \
		schema-mods/enums-and-types.json \
		schema-mods/required-values.json \
		> values.schema.json

	rm values.schema.generated.json

HAS_HELM_DOCS := $(shell command -v helm-docs;)


README.md: README.md.gotmpl values.yaml Chart.yaml
ifdef HAS_HELM_DOCS
	helm-docs
else
	docker run --rm --volume "$(shell pwd):/helm-docs" -u $(shell id -u) jnorwood/helm-docs:latest
endif

docs/RBAC.md: docs/default-values/output.yaml docs/openshift-compatible/output.yaml
	echo "# RBAC Rules for the Kubernetes Monitoring Helm Chart" > docs/RBAC.md
	echo >> docs/RBAC.md
	echo "Several components have specialized RBAC rules to perform their work. This document will list the components, and their RBAC definitions." >> docs/RBAC.md
	echo >> docs/RBAC.md

	echo "## Grafana Alloy" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-alloy") | select(.kind=="ClusterRole") | .rules' docs/examples/default-values/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md
	echo >> docs/RBAC.md

	echo "## Grafana Alloy Events" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-alloy-events") | select(.kind=="ClusterRole") | .rules' docs/default-values/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md
	echo >> docs/RBAC.md

	echo "## Grafana Alloy Logs" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-alloy-logs") | select(.kind=="ClusterRole") | .rules' docs/default-values/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo "When deploying to an OpenShift cluster, these extra rules are added to enable access to a SecurityContextConstraint for the Alloy deployment for gathering Pod Logs:" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-alloy-logs-scc") | select(.kind=="ClusterRole") | .rules' docs/openshift-compatible/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md
	echo >> docs/RBAC.md

	echo "## Grafana Alloy Profiles" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-alloy-profiles") | select(.kind=="ClusterRole") | .rules' docs/profiles-enabled/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md
	echo >> docs/RBAC.md

	echo "## Kube State Metrics" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-kube-state-metrics") | select(.kind=="ClusterRole") | .rules' docs/default-values/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md

	echo >> docs/RBAC.md
	echo "## OpenCost" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-opencost") | select(.kind=="ClusterRole") | .rules' docs/default-values/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md

build-image: test/Dockerfile test/config-analysis.sh test/query-test.sh
	docker build --platform linux/amd64 --tag ghcr.io/grafana/k8s-monitoring-test:$(shell yq -r '.version' Chart.yaml) test

push-image:
	docker push ghcr.io/grafana/k8s-monitoring-test:$(shell yq -r '.version' Chart.yaml)


#
# Test targets
#
.PHONY: test
test: test/test-runner.sh
	./test/test-runner.sh --show-diffs
	cd test; shellspec

#
# Example targets
#
EXAMPLE_RELEASE_NAME=k8smon
EXAMPLE_VALUES_FILES = $(shell find docs/examples -name values.yaml)
EXAMPLE_OUTPUT_FILES = $(EXAMPLE_VALUES_FILES:values.yaml=output.yaml)
METRICS_CONFIG_FILES = $(subst values.yaml,metrics.alloy,$(EXAMPLE_VALUES_FILES))
EVENTS_CONFIG_FILES = $(subst values.yaml,events.alloy,$(EXAMPLE_VALUES_FILES))
LOGS_CONFIG_FILES = $(subst values.yaml,logs.alloy,$(EXAMPLE_VALUES_FILES))
PROFILES_CONFIG_FILES = $(subst values.yaml,profiles.alloy,$(EXAMPLE_VALUES_FILES))
EXAMPLE_ALLOY_FILES = $(METRICS_CONFIG_FILES) $(EVENTS_CONFIG_FILES) $(LOGS_CONFIG_FILES) $(PROFILES_CONFIG_FILES)

alloy_configs = $(shell \
	DIR="$(shell dirname $(1))/" yq e 'with_entries(select(.key == "alloy*")) | select(.[].enabled == true) | to_entries | env(DIR) + .[].key + ".alloy"' $(1) \
)

%/output.yaml: %/values.yaml Chart.yaml Chart.lock values.yaml $(CHART_TEMPLATE_FILES) $(CHART_YAML_FILES)
	helm template $(EXAMPLE_RELEASE_NAME) . -f $< > $@

%/metrics.alloy: %/output.yaml
	yq 'select(.kind=="ConfigMap" and .metadata.name=="$(EXAMPLE_RELEASE_NAME)-alloy") | .data["config.alloy"]' $< > $@

%/events.alloy: %/output.yaml
	yq 'select(.kind=="ConfigMap" and .metadata.name=="$(EXAMPLE_RELEASE_NAME)-alloy-events") | .data["config.alloy"]' $< > $@

%/logs.alloy: %/output.yaml
	yq 'select(.kind=="ConfigMap" and .metadata.name=="$(EXAMPLE_RELEASE_NAME)-alloy-logs") | .data["config.alloy"]' $< > $@

%/profiles.alloy: %/output.yaml
	yq 'select(.kind=="ConfigMap" and .metadata.name=="$(EXAMPLE_RELEASE_NAME)-alloy-profiles") | .data["config.alloy"]' $< > $@

.PHONY: examples clean
examples: $(EXAMPLE_OUTPUT_FILES) $(EXAMPLE_ALLOY_FILES)

clean:
	rm -f $(EXAMPLE_OUTPUT_FILES) $(EXAMPLE_ALLOY_FILES)
