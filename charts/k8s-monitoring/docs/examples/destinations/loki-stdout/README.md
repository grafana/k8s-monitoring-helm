<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Loki Stdout Destination Example

This example demonstrates how to use the `loki-stdout` destination. The `loki-stdout` destination allows you to send
logs to stdout on the Alloy pod that captured them. This can be useful for debugging purposes when you might not want
to deliver certain logs to a Loki instance for persistent storage.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: loki-stdout-destination-test

destinationsMap:
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

  lokiStdout:
    type: loki-stdout
    logProcessingRules: |
      rule {
        source_labels = ["namespace"]
        regex = "production"
        action = "keep"
      }

# Will automatically go to both loki and lokiStdout destinations
podLogs:
  enabled: true

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
