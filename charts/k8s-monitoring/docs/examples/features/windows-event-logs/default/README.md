<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Windows Event Logs

This example demonstrates how to gather event logs from the Windows Nodes in your Kubernetes cluster. It gathers the
`Application` and `System` event log channels using the `loki.source.windowsevent` Alloy component, and requires a
collector using the `windows` preset running as a DaemonSet so an Alloy Pod runs on every Windows Node.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: windows-event-logs-cluster

destinations:
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

windowsEventLogs:
  enabled: true
  collector: alloy-windows
  sources:
    - name: application
      eventLogName: Application
      jobLabel: integrations/windows-application-logs
    - name: system
      eventLogName: System
      jobLabel: integrations/windows-system-logs

collectors:
  alloy-windows:
    presets: [windows, daemonset]
```
<!-- textlint-enable terminology -->
