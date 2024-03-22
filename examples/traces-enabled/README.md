# Traces Enabled

This example contains the values required to enable receiving traces over gRPC or HTTP, and sending them
to [Grafana Tempo](https://grafana.com/oss/tempo/). It also shows how to utilize the span filter to remove traces
triggered by readiness and liveness probes.

```yaml
cluster:
  name: traces-enabled-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
  tempo:
    host: https://tempo.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

traces:
  enabled: true
  receiver:
    filters:
      span:
        - attributes["http.route"] == "/live"
        - attributes["http.route"] == "/healthy"
        - attributes["http.route"] == "/ready"

receivers:
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
