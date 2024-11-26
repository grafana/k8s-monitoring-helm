<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/node-logs/default/values.yaml

## Values

```yaml
---
cluster:
  name: node-logs-cluster

destinations:
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

nodeLogs:
  enabled: true

alloy-logs:
  enabled: true
```
