<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Integration: Alloy

This example demonstrates how to gather metrics from
[Grafana Alloy](https://grafana.com/oss/alloy-opentelemetry-collector/).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: alloy-integration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

integrations:
  alloy:
    instances:
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: alloy-metrics

alloy-metrics:
  enabled: true
```
<!-- textlint-enable terminology -->
