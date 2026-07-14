<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# otel-receiver.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"extraPorts":[{"appProtocol":"grpc","name":"otlp-grpc","port":4317,"protocol":"TCP","targetPort":4317},{"appProtocol":"http","name":"otlp-http","port":4318,"protocol":"TCP","targetPort":4318}]}` | Opens the standard OTLP receiver ports on the collector: 4317 for OTLP gRPC and 4318 for OTLP HTTP. Use this when you want the collector to accept OpenTelemetry data on the conventional ports without enabling a full feature like Application Observability. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# OpenTelemetry Receiver preset

# -- Opens the standard OTLP receiver ports on the collector: 4317 for OTLP gRPC and 4318 for OTLP HTTP. Use this
# when you want the collector to accept OpenTelemetry data on the conventional ports without enabling a full feature
# like Application Observability.
# @section -- Alloy Configuration
alloy:
  extraPorts:
    - name: otlp-grpc
      port: 4317
      targetPort: 4317
      protocol: TCP
      appProtocol: grpc
    - name: otlp-http
      port: 4318
      targetPort: 4318
      protocol: TCP
      appProtocol: http
```
<!-- textlint-enable terminology -->
