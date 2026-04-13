.PHONY: clean
clean:
	rm -f kind-cluster-config.yaml

.PHONY: all
all: kind-cluster-config.yaml

kind-cluster-config.yaml: kind-cluster-config-template.yaml
	yq '.nodes[0].extraMounts[0].hostPath="$(shell pwd)/audit-policy.yaml"' $< > $@
