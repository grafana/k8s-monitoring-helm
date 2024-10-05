<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/integrations/etcd/values.yaml

## Values

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

alloy-metrics:
  enabled: true
```
