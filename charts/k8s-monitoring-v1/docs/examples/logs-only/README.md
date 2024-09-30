# Logs Only

This example shows a deployment that only gathers pod logs and Kubernetes cluster events, but no metrics.

It differs from the [default](../default-values) by not requiring a Prometheus service, disabling the deployment of metric sources (i.e. Kube State Metrics), and disabling the metrics section.

```yaml
cluster:
  name: logs-only-test

externalServices:
  loki:
    host: https://loki.example.com
    tenantId: 2000
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"

metrics:
  enabled: false

kube-state-metrics:
  enabled: false

prometheus-node-exporter:
  enabled: false

prometheus-windows-exporter:
  enabled: false

prometheus-operator-crds:
  enabled: false

opencost:
  enabled: false
```
