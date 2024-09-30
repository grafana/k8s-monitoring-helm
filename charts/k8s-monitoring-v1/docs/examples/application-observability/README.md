# Application Observability

This example shows a method for enabling the metrics, logs, traces, and
profiles with a focus on supporting Application Observability in Grafana Cloud.

Applications can be configured to send data to the OTLP receiver opened on
Grafana Alloy. In addition, [Grafana Beyla](https://grafana.com/oss/beyla-ebpf/)
can be deployed to the cluster and configured to send its data to Alloy.

```yaml
---
cluster:
  name: application-observability-test

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
  pyroscope:
    host: https://pyroscope.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

traces:
  enabled: true
  grafanaCloudMetrics:
    enabled: true

profiles:
  enabled: true
```
