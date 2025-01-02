<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Auto-Instrumentation with Beyla for Metrics and Traces

This example demonstrates how to enable the auto-instrumentation feature, which deploys Grafana Beyla to automatically
instrument your application for metrics collection. It also coordinates with the Application Observability feature to
generate traces for your application.

## Values

```yaml
---
cluster:
  name: annotation-autodiscovery-with-traces-cluster

destinations:
  - name: otlp-gateway
    type: otlp
    url: http://otlp-gateway.example.com
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: true}

applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true

autoInstrumentation:
  enabled: true

alloy-metrics:
  enabled: true

alloy-receiver:
  enabled: true
  alloy:
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP
```
