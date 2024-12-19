<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Prometheus Operator Objects

This example demonstrates how to enable the Prometheus Operator Objects feature to discover and gather metrics from
PodMonitors, ServiceMonitors, and Probes in your Kubernetes cluster.

## Values

```yaml
---
cluster:
  name: prometheus-operator-objects-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

prometheusOperatorObjects:
  enabled: true

alloy-metrics:
  enabled: true
```
