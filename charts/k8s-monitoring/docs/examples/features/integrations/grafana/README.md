<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Integration: Grafana

This example demonstrates how to gather metrics and logs from [Grafana](https://grafana.com/oss/grafana/).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: grafana-integration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

integrations:
  grafana:
    instances:
      - name: grafana
        labelSelectors:
          app.kubernetes.io/name: grafana
        namespaces:
          - o11y

podLogs:
  enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
