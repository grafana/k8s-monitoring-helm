<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/auto-instrumentation/beyla-metrics/values.yaml

## Values

```yaml
---
cluster:
  name: annotation-autodiscovery-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

autoInstrumentation:
  enabled: true

alloy-metrics:
  enabled: true
```
