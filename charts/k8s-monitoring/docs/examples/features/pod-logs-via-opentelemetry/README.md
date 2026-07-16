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
  name: pod-logs-via-opentelemetry

destinations:
  log-storage:
    type: otlp
    protocol: http
    url: http://loki.loki.svc:3100/otlp
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword
    metrics: {enabled: false}
    logs: {enabled: true}
    traces: {enabled: false}

podLogsViaOpenTelemetry:
  enabled: true
  alignServiceNameWithOTelSemConv: true
  namespaces:
    - development
    - production
  namespaceLabels:
    color: color
  # Drop logs from pods that the OpenTelemetry Operator has auto-instrumented for Java,
  # since the Java agent already exports their logs via OTLP.
  filters:
    annotations:
      instrumentation.opentelemetry.io/inject-java: "true"

collectors:
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
    alloy:
      stabilityLevel: public-preview
```
<!-- textlint-enable terminology -->
