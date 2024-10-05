<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/integrations/alloy/values.yaml

## Values

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
      - name: alloy-metrics
        labelSelectors:
          app.kubernetes.io/name: alloy-metrics

alloy-metrics:
  enabled: true
```
