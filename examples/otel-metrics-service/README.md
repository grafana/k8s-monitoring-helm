# OpenTelemetry Metrics Service

This example shows how to change the protocol for the metrics service to send metrics
via otlp or otlphttp protocols.

```yaml
cluster:
  name: otel-metrics-service-test

externalServices:
  prometheus:
    host: prometheus.example.com:443
    queryEndpoint: /api/v1/query
    writeEndpoint: /api/v1/otlp
    protocol: otlphttp
    tls:
      insecure_skip_verify: true
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
    processors:
      memoryLimiter:
        enabled: true
        limit: 100MiB
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
```
