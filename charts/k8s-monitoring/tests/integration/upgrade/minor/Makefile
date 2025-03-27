.PHONY: clean
clean:
	rm collectors.grafana.com_alloy.yaml

collectors.grafana.com_alloy.yaml:
	tar -xzf ../../../../charts/alloy-operator-*.tgz --to-stdout alloy-operator/charts/alloy-crd/crds/collectors.grafana.com_alloy.yaml > $@

.PHONY: all
all: collectors.grafana.com_alloy.yaml
