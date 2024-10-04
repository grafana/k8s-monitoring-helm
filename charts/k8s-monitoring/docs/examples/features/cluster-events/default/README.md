<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/cluster-events/default/values.yaml

## Values

```yaml
---
cluster:
  name: cluster-events-cluster

destinations:
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

clusterEvents:
  enabled: true

alloy-singleton:
  enabled: true
```
