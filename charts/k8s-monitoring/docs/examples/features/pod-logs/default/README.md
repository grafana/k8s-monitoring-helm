<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Pod Logs

This example demonstrates how to gather logs from the Pods in your Kubernetes cluster.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: pod-logs-cluster

destinations:
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

podLogs:
  enabled: true

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
