# Metrics Only

This example shows a deployment that only gathers Prometheus metrics, and does not gather pod logs or Kubernetes cluster events.

It differs from the [default](../default-values) by not requiring a Loki service and disabling the logs section.

```yaml
cluster:
  name: metrics-only-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    username: "12345"
    password: "It's a secret to everyone"

logs:
  enabled: false
```
