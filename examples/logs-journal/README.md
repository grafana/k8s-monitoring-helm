# Logs Only

This example shows a deployment that only gathers pod logs and Kubernetes cluster events, but no metrics.

It differs from the [default](../default-values) by not requiring a Prometheus service, disabling the deployment of metric sources (i.e. Kube State Metrics), and disabling the metrics section.

<!-- values file start -->
```yaml
---
cluster:
  name: logs-journal

externalServices:
  loki:
    host: https://loki.example.com
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"

logs:
  enabled: true
  pod_logs:
    enabled: true
  cluster_events:
    enabled: true
  journal:
    enabled: true
    units: []

metrics:
  enabled: false

receivers:
  grpc:
    enabled: false
  http:
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
<!-- values file end -->
