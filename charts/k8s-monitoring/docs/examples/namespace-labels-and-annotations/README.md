<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Namespaces Labels & Annotations

This example shows how to promote labels and annotations set on the Kubernetes Namespaces to the telemetry data for metrics from that Namespace.

## Metrics


Labels and annotations on Kubernetes objects are not set as metric labels on metrics
like [kube_namespace_annotations](https://github.com/kubernetes/kube-state-metrics/blob/main/docs/metrics/cluster/namespace-metrics.md). This is
because it would greatly increase metric cardinality, which can get costly.

This option is not enabled by default, so this example shows how to enable it. In the values file below, this section
tells the kube-state-metrics deployment to generate the `kube_pod_labels` metric for all labels on the Pod:

This example shows how to extract labels and annotations from the namespace of your application and make them available as resource attributes in your telemetry signals.
These attributes can then be promoted to datapoint attributes (labels) for metrics, log attributes for logs, and resouce attributes traces.

In this example:
	•	the k8sattributes processor is configured to extract the example.com/product annotation and the example.com/team label from the namespace
	•	the transform processor copies those values to datapoint attributes and make them available for application metrics.

As long as these are not promoted these will be available for `target_info` metric.


```
applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true
        port: 4317
      http:
        enabled: true
        port: 4318
    zipkin:
      enabled: true
      port: 9411
  connectors:
    grafanaCloudMetrics:
      enabled: true
  processors:
    k8sattributes:
      annotations:
        - from: namespace
          key: "helvetia.io/application-id"
          tag_name: "leanix_id"
  metrics:
    transforms:
      datapoint:
        - set(attributes["leanix_id"], resource.attributes["leanix_id"])
```

## Values

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

# Omiting default configuration

applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true
        port: 4317
      http:
        enabled: true
        port: 4318
    zipkin:
      enabled: true
      port: 9411
  connectors:
    grafanaCloudMetrics:
      enabled: true
  processors:
    k8sattributes:
      annotations:
        - from: namespace
          key: "example.com/product"
          tag_name: "product" # This is the name of the label that will be used to store the product
                              # product as label is available
      labels:
        - from: namespace
          key: "example.com/team"
          tag_name: "team" # This is the name of the label that will be used to store the team
                           # team as label is available
  metrics:
    transforms:
      datapoint:
        - set(attributes["product"], resource.attributes["product"]) # This adds the product label to the datapoints and similarly you can add to traces and logs
        - set(attributes["team"], resource.attributes["team"]) # This adds the team label to the datapoints and similarly you can add to traces and logs

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
