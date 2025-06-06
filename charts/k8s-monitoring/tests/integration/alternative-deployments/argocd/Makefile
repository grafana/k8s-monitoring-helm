all: deployments/alloy-crd.yaml
clean:
	rm -f deployments/alloy-crd.yaml

ALLOY_OPERATOR_VERSION=$(shell yq '.dependencies[] | select(.name == "alloy-operator") | .version' ../../../../Chart.yaml)
deployments/alloy-crd.yaml:
	wget -O deployments/alloy-crd.yaml https://github.com/grafana/alloy-operator/releases/download/alloy-operator-$(ALLOY_OPERATOR_VERSION)/collectors.grafana.com_alloy.yaml
