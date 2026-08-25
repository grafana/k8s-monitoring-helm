<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Loki Logs Receiver

This example demonstrates how to enable the Loki Logs Receiver feature to receive logs over the Loki API from
applications on your Kubernetes cluster, process them according to defined rules, and then deliver them to Loki.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: loki-logs-receiver-cluster

destinations:
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

lokiLogsReceiver:
  enabled: true
  collector: alloy-receiver
  logProcessingRules: |
    // Add a static label to all received logs so they can be differentiated downstream
    rule {
      target_label = "source"
      replacement = "loki-logs-receiver"
    }

collectors:
  alloy-receiver:
    presets: [deployment]
```
<!-- textlint-enable terminology -->
