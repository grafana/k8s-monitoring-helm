SHELL := /bin/bash
HAS_SHELLSPEC := $(shell command -v shellspec;)

CHART_TEMPLATE_FILES = $(shell find templates -name "*.tpl")
CHART_YAML_FILES = $(shell find templates -name "*.yaml")
ALLOW_LISTS := default_allow_lists/kube-state-metrics.yaml

Chart.lock: Chart.yaml
	helm dependency update .
	@touch Chart.lock # Ensure the timestamp is updated

.SECONDEXPANSION:
values.schema.json: values.yaml $$(wildcard schema-mods/*)
	../../scripts/schema-gen.sh .

default_allow_lists/%.yaml: ../../allowLists/%.yaml
	cp $< $@

README.md: README.md.gotmpl values.yaml Chart.yaml
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-doc-generator --chart /chart > $@

docs/RBAC.md: docs/examples/default-values/output.yaml docs/examples/openshift-compatible/output.yaml docs/examples/profiles-enabled/output.yaml
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
	yq 'select(.metadata.name=="k8smon-alloy-events") | select(.kind=="ClusterRole") | .rules' docs/examples/default-values/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md
	echo >> docs/RBAC.md

	echo "## Grafana Alloy Logs" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-alloy-logs") | select(.kind=="ClusterRole") | .rules' docs/examples/default-values/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo "When deploying to an OpenShift cluster, these extra rules are added to enable access to a SecurityContextConstraint for the Alloy deployment for gathering Pod Logs:" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-alloy-logs-scc") | select(.kind=="ClusterRole") | .rules' docs/examples/openshift-compatible/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md
	echo >> docs/RBAC.md

	echo "## Grafana Alloy Profiles" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-alloy-profiles") | select(.kind=="ClusterRole") | .rules' docs/examples/profiles-enabled/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md
	echo >> docs/RBAC.md

	echo "## Kube State Metrics" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-kube-state-metrics") | select(.kind=="ClusterRole") | .rules' docs/examples/default-values/output.yaml >> docs/RBAC.md
	echo '```' >> docs/RBAC.md

	echo >> docs/RBAC.md
	echo "## OpenCost" >> docs/RBAC.md
	echo >> docs/RBAC.md
	echo '```yaml' >> docs/RBAC.md
	yq 'select(.metadata.name=="k8smon-opencost") | select(.kind=="ClusterRole") | .rules' docs/examples/default-values/output.yaml >> docs/RBAC.md
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
ifdef HAS_SHELLSPEC
	shellspec -c test
else
	docker run --platform linux/amd64 --rm --volume $(shell pwd):/src shellspec/shellspec -c /src/test -s /bin/sh
endif

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

%/output.yaml: %/values.yaml Chart.yaml Chart.lock values.yaml $(CHART_TEMPLATE_FILES) $(CHART_YAML_FILES) $(ALLOW_LISTS)
	helm template $(EXAMPLE_RELEASE_NAME) . -f $< > $@

%/metrics.alloy: %/output.yaml
	yq 'select(.kind=="ConfigMap" and .metadata.name=="$(EXAMPLE_RELEASE_NAME)-alloy") | .data["config.alloy"]' $< > $@

%/events.alloy: %/output.yaml
	yq 'select(.kind=="ConfigMap" and .metadata.name=="$(EXAMPLE_RELEASE_NAME)-alloy-events") | .data["config.alloy"]' $< > $@

%/logs.alloy: %/output.yaml
	yq 'select(.kind=="ConfigMap" and .metadata.name=="$(EXAMPLE_RELEASE_NAME)-alloy-logs") | .data["config.alloy"]' $< > $@

%/profiles.alloy: %/output.yaml
	yq 'select(.kind=="ConfigMap" and .metadata.name=="$(EXAMPLE_RELEASE_NAME)-alloy-profiles") | .data["config.alloy"]' $< > $@

.PHONY: examples
examples: $(EXAMPLE_OUTPUT_FILES) $(EXAMPLE_ALLOY_FILES)

.PHONY: build
build: Chart.lock README.md examples values.schema.json $(ALLOW_LISTS)

.PHONY: clean
clean:
	rm -f README.md values.schema.json $(EXAMPLE_OUTPUT_FILES) $(EXAMPLE_ALLOY_FILES) $(ALLOW_LISTS)
