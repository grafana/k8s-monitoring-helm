# Images

The following is the list of images potentially used in the 3.0.0 version of the k8s-monitoring Helm chart:

| Image Name | Repository | Feature |
| ---------- | ---------- | ------- |
| Alloy Operator | ghcr.io/grafana/alloy-operator:1.1.0 | Always used. Deploys and manages Grafana Alloy collector instances. |
| Beyla | docker.io/grafana/beyla:2.0.3 | Automatically instruments apps on the cluster, generating metrics and traces. Enabled with `autoInstrumentation.beyla.enabled=true`. |
| Kepler | quay.io/sustainable_computing_io/kepler:release-0.8.0 | Gathers energy metrics for Kubernetes objects. Enabled with `clusterMetrics.kepler.enabled=true`. |
| kube-state-metrics | registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.15.0 | Gathers Kubernetes cluster object metrics. Enabled with `clusterMetrics.kube-state-metrics.deploy=true`. |
| Node Exporter | quay.io/prometheus/node-exporter:v1.9.1 | Gathers Kubernetes cluster node metrics. Enabled with `clusterMetrics.node-exporter.deploy=true`. |
| OpenCost | ghcr.io/opencost/opencost:1.113.0@sha256:b313d6d320058bbd3841a948fb636182f49b46df2368d91e2ae046ed03c0f83c | Gathers cost metrics for Kubernetes objects. Enabled with `clusterMetrics.opencost.enabled=true`. |
| Windows Exporter | ghcr.io/prometheus-community/windows-exporter:0.30.7 | Gathers Kubernetes cluster node metrics for Windows nodes. Enabled with `clusterMetrics.windows-exporter.deploy=true`. |
