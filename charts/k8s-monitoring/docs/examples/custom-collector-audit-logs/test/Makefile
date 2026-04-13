AUDIT_POLICY_PATH := $(realpath dependencies/audit-policy.yaml)

.PHONY: all clean

all: kind-cluster-config.yaml

kind-cluster-config.yaml: kind-cluster-config.yaml.tmpl dependencies/audit-policy.yaml
	sed 's|AUDIT_POLICY_PATH|$(AUDIT_POLICY_PATH)|' $< > $@

clean:
	rm -f kind-cluster-config.yaml
