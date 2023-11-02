# Control plane metrics

This example shows a deployment that enables gathering of control plane metrics.

For now, that is just the API Server, but other metric sources will be added soon.

```yaml
cluster:
  name: control-plane-metrics-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    tenantId: 1000
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

metrics:
  apiserver:
    enabled: true
  kubeControllerManager:
    enabled: true
  kubeProxy:
    enabled: true
  kubeScheduler:
    enabled: true
```
