<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Tolerations

This example shows how to apply [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
to various kinds of workloads deployed by this Helm chart. This can be used to allow workloads to run on nodes with
specific taints, or to prevent workloads from running on nodes with specific taints.

## Values

```yaml
---
cluster:
  name: tolerations-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

clusterMetrics:
  enabled: true
  kube-state-metrics:
    tolerations:
      - effect: NoSchedule
        operator: Exists
  node-exporter:
    tolerations:
      - effect: NoSchedule
        operator: Exists
  windows-exporter:
    tolerations:
      - effect: NoSchedule
        operator: Exists

podLogs:
  enabled: true

alloy-metrics:
  enabled: true
  controller:
    tolerations:
      - effect: NoSchedule
        operator: Exists

alloy-logs:
  enabled: true
  controller:
    tolerations:
      - effect: NoSchedule
        operator: Exists
```
