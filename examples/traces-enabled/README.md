# Traces Enabled

This example contains the values required to enable receiving traces over gRPC or HTTP, and sending them to [Grafana Tempo](https://grafana.com/oss/tempo/).

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

grafana-agent:
  agent:
    extraPorts:
      - name: "otlp-traces-grpc"
        port: 4317
        targetPort: 4317
        protocol: "TCP"
      - name: "otlp-traces-http"
        port: 4318
        targetPort: 4318
        protocol: "TCP"
```
