.PHONY: check
check:
	if yq eval '.version' ../../../../Chart.yaml | grep -q "[[:digit:]]\+\.0\.[[:digit:]]\+"; then \
		echo "Minor version is 0."; \
		exit 2; \
	fi

.PHONY: clean
clean:
	rm -f collectors.grafana.com_alloy.yaml

collectors.grafana.com_alloy.yaml:
	tar -xzf ../../../../charts/alloy-operator-*.tgz --to-stdout alloy-operator/charts/alloy-crd/crds/collectors.grafana.com_alloy.yaml > $@

.PHONY: all
all: collectors.grafana.com_alloy.yaml

.PHONY: run-test
run-test:
	../../../../../../scripts/run-cluster-test.sh .
