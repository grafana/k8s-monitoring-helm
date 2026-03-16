<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Integration: cert-manager

This example demonstrates how to gather metrics from [cert-manager](https://cert-manager.io/).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: cert-manager-integration-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

integrations:
  collector: alloy-metrics
  cert-manager:
    instances:
      - name: cert-manager
        labelSelectors:
          app.kubernetes.io/name: cert-manager

collectors:
  alloy-metrics: {}

```
<!-- textlint-enable terminology -->
