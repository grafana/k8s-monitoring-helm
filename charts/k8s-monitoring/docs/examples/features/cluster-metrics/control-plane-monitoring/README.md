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
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  loki:
    type: loki
    url: http://loki.loki.svc:3100/api/push

# Features
clusterEvents:
  enabled: true
  collector: alloy-singleton

clusterMetrics:
  enabled: true
  collector: alloy-metrics
  controlPlane:
    enabled: true

hostMetrics:
  enabled: true
  collector: alloy-metrics
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true

podLogs:
  enabled: true
  collector: alloy-logs

integrations:
  collector: alloy-metrics
  etcd:
    instances:
      - name: k8s-controlplane-etcd
        labelSelectors:
          app.kubernetes.io/component: etcd

# Collectors
collectors:
  alloy-metrics:
    presets: [clustered, statefulset]

  alloy-logs:
    presets: [filesystem-log-reader, daemonset]

  alloy-singleton:
    presets: [singleton]

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
