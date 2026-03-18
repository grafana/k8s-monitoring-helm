<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Integration: etcd

This example demonstrates how to gather metrics from [etcd](https://etcd.io/).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: etcd-integration-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

integrations:
  collector: alloy-metrics
  etcd:
    instances:
      - name: etcd
        labelSelectors:
          app.kubernetes.io/component: etcd

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
```
<!-- textlint-enable terminology -->
