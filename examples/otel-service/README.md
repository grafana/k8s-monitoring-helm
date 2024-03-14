# OpenTelemetry Service

This example shows how to change the protocol to send metrics, logs and traces via otlp or otlphttp protocols.
The `<OTLP endpoint>` refers to any backend that is compatible with OTLP.

```yaml
cluster:
  name: otel-service-test

externalServices:
  prometheus:
    host: prometheus.example.com:443 or <OTLP endpoint>
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
    host: https://loki.example.com or <OTLP endpoint>
    protocol: otlphttp
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

  tempo:
    host: https://tempo.example.com or <OTLP endpoint>
    protocol: otlphttp
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

traces:
  enabled: true

receivers:
  otlp:
    grcp:
      enabled: true
    http:
      enabled: true
  jaeger:
    grpc:
      enabled: true
    thriftBinary:
      enabled: true
    thriftCompact:
      enabled: true
    thriftHttp:
      enabled: true
  zipkin:
    enabled: true
```
