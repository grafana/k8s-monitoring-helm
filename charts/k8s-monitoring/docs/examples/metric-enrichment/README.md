<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Metric Enrichment

This example shows how to use the `prometheus.enrich` component to attach labels to metrics from other sources.
In this example, we get the list of pods, extract the `color` label that's on the namespace, then combine that with any
metrics that have both `namespace` and `pod` already set. This is all done in a custom destination, which then forwards
to the standard Prometheus destination

Sending `clusterMetrics` to the custom destination will ensure that the metrics go through the enrichment process first.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: metric-enrichment-test-cluster

destinations:
  - name: metric-store
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
    metricEnrichment:
      podLabels: [color]
      namespaceLabels: [team]

clusterMetrics:
  enabled: true

alloy-metrics:
  enabled: true
  includeDestinations: [metric-store]
  alloy:
    stabilityLevel: experimental
```
<!-- textlint-enable terminology -->
