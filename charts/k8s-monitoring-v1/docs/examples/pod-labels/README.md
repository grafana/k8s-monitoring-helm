# Pod Labels

This example shows how to include labels set on the Kubernetes Pod to the metrics and logs for that Pod.

## Metrics

Labels and annotations on Kubernetes objects are not set as metric labels on metrics
like [kube_pod_info](https://github.com/kubernetes/kube-state-metrics/blob/main/docs/pod-metrics.md). This is
because it would greatly increase metric cardinality, which can get
costly. [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
can optionally create additional metrics. For example, the `kube_pod_labels` metric will have labels that match the
Pod's Kubernetes labels. This metrics can then be joined to other metrics.

This option is not enabled by default, so this example shows how to enable it. In the values file below, this section
tells the kube-state-metrics deployment to generate the `kube_pod_labels` metric for all labels on the Pod:

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

Expanding this beyond Pods, additional fields can be added to kube-state-metrics' `metricLabelsAllowlist` to get label
metrics for other objects, such as Deployments, Namespaces, Nodes, etc.

Also, kube-state-metrics can generate metrics for annotations with `metricAnnotationsAllowList`.
See the [kube-state-metrics documentation](https://github.com/kubernetes/kube-state-metrics) and
[kube-state-metrics Helm chart documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics)
for more information.

## Logs

Also, the Pod logs gathered and sent to Loki do not have their Pod's Kubernetes labels attached. This is enabled
with a relabeling rule. In the example below, the `app.kubernetes.io/instance` Kubernetes label (discovered by
the [discovery.kubernetes component](https://grafana.com/docs/alloy/latest/reference/components/discovery.kubernetes/#pod-role))
is set to the `instance` label on the log message:

```yaml
logs:
  pod_logs:
    extraRelabelingRules: |
      rule {
        source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_instance"]
        action = "replace"
        target_label = "instance"
      }
```

Here is an alternative that sets all Kubernetes Pod labels to log labels. NOTE: doing this with Pods with many labels
may lead to efficiency, performance, or functionality issues. Try to limit the number of labels to a useful minimal set
of labels.

```yaml
logs:
  pod_logs:
    extraRelabelingRules: |
      rule {
        action = "labelmap"
        regex = "__meta_kubernetes_pod_label_(.+)"
      }
```

## values.yaml

```yaml
cluster:
  name: pod-labels-test

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

logs:
  pod_logs:
    extraRelabelingRules: |
      rule {
        source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_instance"]
        action = "replace"
        target_label = "instance"
      }

test:
  extraQueries:
    - query: "kube_pod_labels{cluster=\"kube-pod-labels-test\"}"
      type: promql

kube-state-metrics:
  metricLabelsAllowlist:
    - pods=[*]
```
