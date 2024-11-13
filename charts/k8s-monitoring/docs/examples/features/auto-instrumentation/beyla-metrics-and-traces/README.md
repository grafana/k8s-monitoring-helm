<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/auto-instrumentation/beyla-metrics-and-traces/values.yaml

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
