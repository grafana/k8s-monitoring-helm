kube-prometheus-stack-release.yaml: ../kube-prometheus-stack-values.yaml
	{ \
		echo "---"; \
		echo "apiVersion: helm.toolkit.fluxcd.io/v2"; \
		echo "kind: HelmRelease"; \
		echo "metadata:"; \
		echo "  name: kube-prometheus-stack"; \
		echo "  namespace: monitoring"; \
		echo "spec:"; \
		echo "  interval: 1m"; \
		echo "  chart:"; \
		echo "    spec:"; \
		echo "      chart: kube-prometheus-stack"; \
		echo "      sourceRef:"; \
		echo "        kind: HelmRepository"; \
		echo "        name: prometheus-community"; \
		echo "        namespace: flux-system"; \
		echo "      interval: 1m"; \
		echo "  values:"; \
	} > kube-prometheus-stack-release.yaml
	cat ../kube-prometheus-stack-values.yaml | sed 's/^/    /' >> kube-prometheus-stack-release.yaml

.PHONY: all
all: kube-prometheus-stack-release.yaml
