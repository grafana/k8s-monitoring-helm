<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/prometheus-operator-objects/default/values.yaml

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
