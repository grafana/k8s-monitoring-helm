# GKE Autopilot

Kubernetes Clusters with fully managed control planes like [GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
need extra consideration because they often have restrictions around DaemonSets and node access. This prevents services
like Node Exporter from working properly.

This example shows how to disable Node Exporter.

Missing Node Exporter metrics is likely fine, because users of these clusters should not need concern themselves with
the health of the nodes. That's the responsibility of the cloud provider.

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
