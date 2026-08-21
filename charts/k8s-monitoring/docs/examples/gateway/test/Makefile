.PHONY: all clean
all: k8s-monitoring-cluster-one.yaml k8s-monitoring-cluster-two.yaml

clean: ;

k8s-monitoring-cluster-one.yaml: ../cluster-one-values.yaml
	yq eval -i "with(select(documentIndex==2); .spec.values = load(\"$<\"))" $@

k8s-monitoring-cluster-two.yaml: ../cluster-two-values.yaml
	yq eval -i "with(select(documentIndex==2); .spec.values = load(\"$<\"))" $@
