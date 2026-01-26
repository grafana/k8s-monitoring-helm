<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# PodLogs Objects

This example demonstrates how to gather logs from the Pods in your Kubernetes cluster using [PodLogs objects](https://doc.crds.dev/github.com/grafana/alloy/monitoring.grafana.com/PodLogs/v1alpha2).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: pod-logs-objects-cluster

destinations:
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

podLogsObjects:
  enabled: true
  nodeFilter: true

alloy-logs:
  enabled: true
  liveDebugging:
    enabled: true
  alloy:
    clustering:
      enabled: true
```
<!-- textlint-enable terminology -->
