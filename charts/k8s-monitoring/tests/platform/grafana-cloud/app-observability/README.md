<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Grafana Cloud: Application Observability

This is a feature test rather than a platform variation. It verifies the Application Observability feature against a
Grafana Cloud [OTLP gateway](https://grafana.com/docs/grafana-cloud/send-data/otlp/) destination: an Alloy collector
accepts OTLP metrics, logs, and traces over gRPC and HTTP, applies span transforms, and forwards the telemetry to
Grafana Cloud.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: application-observability-gc-feature-test

destinations:
  otlp-gateway:
    type: otlp
    url: https://otlp-gateway-prod-us-east-0.grafana.net/otlp
    protocol: http
    auth:
      type: basic
      usernameKey: OTLP_GATEWAY_USER
      passwordKey: OTLP_GATEWAY_PASS
    secret:
      create: false
      name: grafana-cloud-credentials
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: true}
    processors:
      batch:
        size: 4096
        maxSize: 4096

applicationObservability:
  enabled: true
  collector: alloy-receiver
  traces:
    transforms:
      span:
        - replace_pattern(name, "\\?.*", "")
        - replace_match(name, "GET /api/products/*", "GET /api/products/{productId}")

  receivers:
    otlp:
      grpc:
        enabled: true
      http:
        enabled: true

  processors:
    k8sattributes:
      otelAnnotations: true

podLogsViaLoki:
  enabled: true
  collector: alloy-logs
  destinations:
    - otlp-gateway

collectors:
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
  alloy-receiver:
    presets: [deployment]
```
<!-- textlint-enable terminology -->
