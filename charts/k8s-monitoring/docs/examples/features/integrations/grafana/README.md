<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/integrations/grafana/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: grafana-integration-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  loki:
    type: loki
    url: http://loki.loki.svc:3100/api/push

integrations:
  collector: alloy-metrics
  grafana:
    instances:
      - name: grafana
        labelSelectors:
          app.kubernetes.io/name: grafana
        namespaces:
          - o11y

podLogs:
  enabled: true
  collector: alloy-logs

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]

  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
```
<!-- textlint-enable terminology -->
