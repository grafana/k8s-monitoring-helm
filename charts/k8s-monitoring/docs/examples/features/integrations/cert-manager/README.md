<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/integrations/cert-manager/values.yaml

## Values

```yaml
---
cluster:
  name: cert-manager-integration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

integrations:
  cert-manager:
    instances:
      - name: cert-manager

alloy-metrics:
  enabled: true
```
