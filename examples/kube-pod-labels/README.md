# Kube Pod Labels

This example shows how to include Pod labels as metrics.

Labels and annotations on Kubernetes objects are not set as metric labels on metrics like [kube_pod_info](https://github.com/kubernetes/kube-state-metrics/blob/main/docs/pod-metrics.md). This is
because it would greatly increase metric cardinality, which can get costly. [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
can optionally create additional metrics. For example, `kube_pod_labels` create label metrics that can then be joined to
other pod metrics. This option is not enabled by default.

In the values file below, this section tells the kube-state-metrics deployment to generate the `kube_pod_labels` metric:
```yaml
kube-state-metrics:
  metricLabelsAllowlist:
    - pods=[*]
```
And this section tells Alloy to include that metric in the set that gets sent to Prometheus for storage:
```yaml
metrics:
  kube-state-metrics:
    metricsTuning:
      includeMetrics: [kube_pod_labels]
```

Additional fields can be added to `metricLabelsAllowlist` to get label metrics for other objects, such as Namespaces, Nodes, etc.
Also, kube-state-metrics can generate metrics for annotations with `metricAnnotationsAllowList`.
See the [kube-state-metrics documentation](https://github.com/kubernetes/kube-state-metrics) and
[Helm chart documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) for more information.

## values.yaml
```yaml
cluster:
  name: kube-pod-labels-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

metrics:
  kube-state-metrics:
    metricsTuning:
      includeMetrics: [kube_pod_labels]

test:
  extraQueries:
    - query: "kube_pod_labels{cluster=\"kube-pod-labels-test\"}"
      type: promql

kube-state-metrics:
  metricLabelsAllowlist:
    - pods=[*]
```
