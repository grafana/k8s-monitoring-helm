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
  loki:
    type: loki
    url: http://loki.loki.svc:3100/api/push

podLogsViaLoki:
  enabled: true

collectors:
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
```
<!-- textlint-enable terminology -->
