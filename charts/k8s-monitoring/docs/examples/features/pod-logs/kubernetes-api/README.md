<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Pod Logs

This example demonstrates how to gather logs from the Pods in your Kubernetes cluster by streaming from the Kubernetes
API. This is useful when you cannot use the hostPath volume mount method to access the logs directly from the file
system.

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
  gatherMethod: kubernetesApi

alloy-logs:
  enabled: true
  alloy:
    clustering:
      enabled: true
    mounts:
      varlog: false
      dockercontainers: false
```
<!-- textlint-enable terminology -->
