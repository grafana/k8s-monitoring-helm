<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Integration: Loki

This example demonstrates how to gather metrics and logs from [Grafana Loki](https://grafana.com/oss/loki/).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: loki-integration-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  loki:
    type: loki
    url: http://loki.loki.svc:3100/api/push

integrations:
  collector: alloy-metrics
  loki:
    instances:
      - name: loki
        labelSelectors:
          app.kubernetes.io/name: loki
        logs:
          enabled: true

podLogsViaLoki:
  enabled: true
  collector: alloy-logs

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
```
<!-- textlint-enable terminology -->
