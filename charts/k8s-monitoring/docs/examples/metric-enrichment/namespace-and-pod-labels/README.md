<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Namespace and Pod Labels

This example shows how to enrich your cluster metrics with labels from Kubernetes Namespaces and Pods using the metricEnrichment feature on Prometheus destinations.

The `metricEnrichment` feature allows you to automatically add labels from Kubernetes resources to your metrics:

-   `namespaceLabels`: Extract labels from the Namespace that the metric's pod belongs to
-   `podLabels`: Extract labels from the Pod that generated the metric

This is useful for adding organizational metadata like team names, environments, or application versions to your metrics for better filtering and grouping in your observability platform. This is especially useful from a FinOps perspective, enabling cost attribution and chargeback by tracking which teams, environments, or components are generating metrics.

In this example:

-   The `namespaceLabels` field extracts the `team_name` and `environment` labels from namespaces
-   The `podLabels` field extracts the `app_version` and `component` labels from pods
-   These labels are automatically added to all cluster metrics sent to the destination

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: metric-enrichment-example

destinations:
  - name: metric-store
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
    metricEnrichment:
      namespaceLabels:
        - team_name
        - environment
      podLabels:
        - app_version
        - component

clusterMetrics:
  enabled: true

hostMetrics:
  enabled: true
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true

alloy-metrics:
  enabled: true
  alloy:
    stabilityLevel: experimental

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
