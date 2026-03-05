<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Pod Logs - Multiline

This example demonstrates how to gather logs from the Pods in your Kubernetes cluster, and use the `match` and
`multiline` processing stages to handle multiline logs from a specific pod.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: multiline-pod-logs

destinations:
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: 1
    auth:
      type: basic
      username: loki
      password: lokipassword

podLogs:
  enabled: true
  extraLogProcessingStages: |
    stage.match {
      selector = "{app_kubernetes_io_name=\"multiline-pod\"}"
      stage.multiline {
        firstline = "^level=[A-Z]+"
      }
    }

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
