<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Cluster Metrics

This example demonstrates how to enable the Cluster Metrics feature to gather metrics about the Kubernetes Cluster and
deliver them to a metrics destination.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: cluster-metrics-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  kepler:
    enabled: true
  opencost:
    enabled: true
    metricsSource: prometheus
    opencost:
      exporter:
        defaultClusterId: cluster-metrics-example-cluster
      prometheus:
        external:
          url: http://prometheus.prometheus.svc:9090/api/v1/query

alloy-metrics:
  enabled: true
```
<!-- textlint-enable terminology -->
