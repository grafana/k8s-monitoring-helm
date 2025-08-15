SHELL := /bin/bash
HAS_SHELLSPEC := $(shell command -v shellspec;)

CHART_TEMPLATE_FILES := $(shell find templates -name "*.tpl")
CHART_YAML_FILES := $(shell find templates -name "*.yaml")
ALLOW_LISTS := default_allow_lists/kube-state-metrics.yaml

Chart.lock: Chart.yaml
	helm dependency update .
	@touch Chart.lock # Ensure the timestamp is updated

.SECONDEXPANSION:
values.schema.json: values.yaml $$(wildcard schema-mods/*)
	docker run --rm --platform linux/amd64 --volume $(shell pwd):/chart ghcr.io/grafana/helm-chart-toolbox-schema-generator --chart /chart > $@

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
EXAMPLE_VALUES_FILES := $(shell find docs/examples -name values.yaml)
EXAMPLE_OUTPUT_FILES := $(EXAMPLE_VALUES_FILES:values.yaml=output.yaml)
%/output.yaml: %/values.yaml Chart.yaml Chart.lock values.yaml values.schema.json $(CHART_TEMPLATE_FILES) $(CHART_YAML_FILES) $(ALLOW_LISTS)
	../../scripts/generate-example.sh $(shell pwd) $(shell dirname $<)

INTEGRATION_TEST_VALUES_FILES := $(shell find tests/integration -name values.yaml)
INTEGRATION_TEST_OUTPUT_FILES := $(INTEGRATION_TEST_VALUES_FILES:values.yaml=.rendered/output.yaml)
%/.rendered/output.yaml: %/values.yaml Chart.yaml Chart.lock values.yaml values.schema.json $(CHART_TEMPLATE_FILES) $(CHART_YAML_FILES) $(ALLOW_LISTS)
	../../scripts/generate-example.sh $(shell pwd) $(shell dirname $<) --output-dir .rendered --no-alloy --no-readme

.PHONY: examples
examples: $(EXAMPLE_OUTPUT_FILES) $(INTEGRATION_TEST_OUTPUT_FILES)

.PHONY: build build-chart build-docs build-examples
build: build-chart build-docs build-examples
build-chart: Chart.lock values.schema.json $(ALLOW_LISTS)
build-docs: README.md
build-examples: examples

.PHONY: clean
clean:
	rm -f README.md values.schema.json $(EXAMPLE_OUTPUT_FILES) $(ALLOW_LISTS)
