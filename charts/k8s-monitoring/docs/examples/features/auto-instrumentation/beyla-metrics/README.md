<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Zero-code instrumentation with Beyla for Metrics

This example demonstrates how to enable the zero-code feature, which deploys Grafana Beyla to automatically
instrument your application for metrics collection.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: auto-instrumentation-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

autoInstrumentation:
  enabled: true
  collector: alloy-metrics
  spanMetricsOnly: true

collectors:
  alloy-metrics: {}
```
<!-- textlint-enable terminology -->
