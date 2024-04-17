# Tail sampling

This example contains an example of [tail sampling](https://grafana.com/docs/grafana-cloud/monitor-applications/application-observability/setup/sampling/tail/).

```yaml
cluster:
  name: tail-sampling-test

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
  enabled: false

logs:
  enabled: false
  
traces:
  enabled: true
  receiver:
    tailsampling:
      policies:
        - name: all_traces_above_500
          type: latency
          latency:
            thresholdMs: 500

```
