<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# GKE Autopilot

Kubernetes Clusters with fully managed control planes like [GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
need extra consideration because they often have restrictions around DaemonSets and node access. This prevents services
like Node Exporter from working properly.

This example shows how to disable Node Exporter.

Missing Node Exporter metrics is likely fine, because users of these clusters should not need concern themselves with
the health of the nodes. That's the responsibility of the cloud provider.

## Values

```yaml
---
cluster:
  name: gke-autopilot-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

clusterMetrics:
  enabled: true
  node-exporter:
    deploy: false
    enabled: false

clusterEvents:
  enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true
alloy-singleton:
  enabled: true
alloy-logs:
  enabled: true
```
