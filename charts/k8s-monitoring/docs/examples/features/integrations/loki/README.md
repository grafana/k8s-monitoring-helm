<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/integrations/loki/values.yaml

## Values

```yaml
---
cluster:
  name: loki-integration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

integrations:
  loki:
    instances:
      - name: loki
        labelSelectors:
          app.kubernetes.io/name: loki
        logs:
          enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true
```
