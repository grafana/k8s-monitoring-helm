<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Cluster Metrics with Control Plane Monitoring

This example demonstrates how to enable the Cluster Metrics feature to gather metrics about the Kubernetes Cluster,
including the control plane components, and deliver them to a metrics destination.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: cluster-metrics-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

# Features
clusterEvents:
  enabled: true

clusterMetrics:
  enabled: true
  controlPlane:
    enabled: true

podLogs:
  enabled: true

integrations:
  etcd:
    instances:
      - name: k8s-controlplane-etcd
        labelSelectors:
          app.kubernetes.io/component: etcd

# Collectors
alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true

alloy-singleton:
  enabled: true
```
<!-- textlint-enable terminology -->
