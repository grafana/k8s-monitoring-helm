<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Prometheus Metrics Receiver

This example demonstrates how to enable the Prometheus Metrics Receiver feature to receive metrics from applications on
your Kubernetes cluster via Prometheus remote write, process them according to defined rules, and then deliver them to
Prometheus.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: prometheus-metrics-receiver

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write

prometheusMetricsReceiver:
  enabled: true
  collector: alloy-receiver
  metricProcessingRules: |
    // Stamp every received metric with a label identifying that it arrived via the
    // remote write receiver. Any prometheus.relabel rule block is valid here.
    rule {
      target_label = "source"
      replacement = "prometheus-remote-write"
    }

collectors:
  alloy-receiver:
    presets: [deployment]
```
<!-- textlint-enable terminology -->
