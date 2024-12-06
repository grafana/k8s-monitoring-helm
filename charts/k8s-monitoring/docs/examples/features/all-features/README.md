<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/all-features/values.yaml

## Values

```yaml
---
cluster:
  name: all-features-cluster

destinations:
  - name: otlpGateway
    type: otlp
    url: https://otlp.example.com:4317/v1/traces
    auth:
      type: basic
      username: "my-username"
      password: "my-password"
    metrics: { enabled: true }
    logs:    { enabled: true }
    traces:  { enabled: true }
  - name: pyroscope
    type: pyroscope
    url: http://pyroscope.example.com

# Features
clusterMetrics:
  enabled: true
  kepler: { enabled: true }
clusterEvents: { enabled: true }

podLogs: { enabled: true }
applicationObservability:
  enabled: true
  receivers:
    grpc:
      enabled: true
annotationAutodiscovery: { enabled: true }
prometheusOperatorObjects: { enabled: true }
profiling: { enabled: true }
integrations:
  alloy:
    instances:
      - name: alloy

# Collectors
alloy-metrics: { enabled: true }

alloy-logs: { enabled: true }

alloy-singleton: { enabled: true }
alloy-receiver:
  enabled: true
  alloy:
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP
alloy-profiles: { enabled: true }```
