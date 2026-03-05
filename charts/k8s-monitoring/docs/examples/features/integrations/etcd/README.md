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
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

integrations:
  etcd:
    instances:
      - name: etcd
        labelSelectors:
          app.kubernetes.io/component: etcd

alloy-metrics:
  enabled: true
```
<!-- textlint-enable terminology -->
