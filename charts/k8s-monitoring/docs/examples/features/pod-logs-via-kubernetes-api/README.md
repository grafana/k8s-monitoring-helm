<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Pod Logs via Kubernetes API

This example demonstrates how to gather logs from the Pods in your Kubernetes cluster by streaming from the Kubernetes
API. This is useful when you cannot use the `hostPath` volume mount method to access the logs directly from the file
system.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: pod-logs-via-k8s-api-cluster

destinations:
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

podLogsViaKubernetesApi:
  enabled: true
  namespaces: [production]

alloy-logs:
  enabled: true
  alloy:
    clustering:
      enabled: true
```
<!-- textlint-enable terminology -->
