all: kind-cluster-config.yaml
kind-cluster-config.yaml:
	echo "---" > kind-cluster-config.yaml
	echo "apiVersion: kind.x-k8s.io/v1alpha4" >> kind-cluster-config.yaml
	echo "kind: Cluster" >> kind-cluster-config.yaml
	echo "nodes:" >> kind-cluster-config.yaml
	echo "  - role: control-plane" >> kind-cluster-config.yaml
	echo "    extraMounts:" >> kind-cluster-config.yaml
	echo "      - hostPath: $(shell realpath "$(shell pwd)/../../../../../..")" >> kind-cluster-config.yaml
	echo "        containerPath: /mnt/k8s-monitoring-helm.git" >> kind-cluster-config.yaml
	echo "        readOnly: true" >> kind-cluster-config.yaml
