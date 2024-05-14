# GKE Autopilot

Kubernetes Clusters with fully managed control planes like [GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
need special consideration because they often have special restrictions around DaemonSets and node access. This prevents
services like Node Exporter from working properly.

This example shows how to disable Node Exporter. Obviously, you won't see node metrics,

```yaml
cluster:
  name: gke-autopilot-test

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

metrics:
  node-exporter:
    enabled: false

prometheus-node-exporter:
  enabled: false
```
