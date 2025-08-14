<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Pod Labels & Annotations

This example shows how to include labels and annotations set on the Kubernetes Pod to the telemetry data for that Pod.

## Metrics

Labels and annotations on Kubernetes objects are not set as metric labels on metrics
like [kube_pod_info](https://github.com/kubernetes/kube-state-metrics/blob/main/docs/pod-metrics.md). This is
because it would greatly increase metric cardinality, which can get costly.
[kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) can optionally create additional metrics. For
example, the `kube_pod_labels` metric will have labels that match the Pod's Kubernetes labels. These metrics can then be
joined to other metrics.

This option is not enabled by default, so this example shows how to enable it. In the values file below, this section
tells the kube-state-metrics deployment to generate the `kube_pod_labels` metric for all labels on the Pod:

```yaml
clusterMetrics:
  kube-state-metrics:
    metricLabelsAllowlist:
      - pods=[*]
```

Similarly, this section tells the kube-state-metrics deployment to generate the `kube_pod_annotations` metric for all
annotations on the Pod:

```yaml
clusterMetrics:
  kube-state-metrics:
    metricAnnotationsAllowList:
      - pods=[*]
```

Finally, this section tells Alloy to include those metrics in the set that gets sent to the metrics destination for
storage:

```yaml
clusterMetrics:
  kube-state-metrics:
    metricsTuning:
      includeMetrics: [kube_pod_annotations, kube_pod_labels]
```

Expanding this beyond Pods, additional fields can be added to kube-state-metrics' `metricLabelsAllowlist` to get label
metrics for other objects, such as Deployments, Namespaces, Nodes, etc. See the
[kube-state-metrics documentation](https://github.com/kubernetes/kube-state-metrics) and
[kube-state-metrics Helm chart documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics)
for more information.

## Logs

Also, the Pod logs gathered and sent to the logs destination do not have their Pod's Kubernetes labels or annotations
attached. This can be enabled in the Pod Logs feature. In the example below, the `example.com/name` Kubernetes Pod label
is set to the `name` label on the log message, and the `example.com/environment` Kubernetes Pod annotation is set to the
`environment` label on the log message:

```yaml
podLogs:
  labels:
    name: example.com/name
  annotations:
    environment: example.com/environment
  labelsToKeep: [name, environment]
```

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: pod-labels-and-annotations

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push
  - name: tempo
    type: otlp
    url: http://tempo.tempo.svc
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

clusterMetrics:
  enabled: true
  kube-state-metrics:
    metricsTuning:
      includeMetrics:
        - kube_pod_annotations
        - kube_pod_labels
    metricLabelsAllowlist:       # Configures kube-state-metrics to capture Pod labels as kube_pod_labels metrics
      - pods=[*]
    metricAnnotationsAllowList:  # Configures kube-state-metrics to capture Pod annotations as kube_pod_annotations metrics
      - pods=[*]

podLogs:
  enabled: true
  labels:       # Capture the `example.com/name` Pod label as the `name` log label
    name: example.com/name
  annotations:  # Capture the `example.com/environment` Pod annotation as the `environment` log label
    environment: example.com/environment
  labelsToKeep: [name, environment]

applicationObservability:
  enabled: true
  processors:
    k8sattributes:
      labels:
        - from: pod
          key_regex: "kubernetes.io/(.*)"
          tag_name: "$1"
  receivers:
    otlp:
      grpc:
        enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true

alloy-receiver:
  enabled: true
  alloy:
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP
```
<!-- textlint-enable terminology -->
