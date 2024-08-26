# Beyla

This example shows how to deploy and gather telemetry data from [Grafana Beyla](https://grafana.com/oss/beyla-ebpf/).

Beyla is an eBPF-based auto-instrumentation tool that generates metrics and traces from your applications.

```yaml
---
cluster:
  name: beyla-test

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

metrics:
  beyla:
    enabled: true

traces:
  enabled: true

beyla:
  enabled: true
```