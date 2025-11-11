<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Tolerations

This example shows how to apply [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
to various kinds of workloads deployed by this Helm chart. This can be used to allow workloads to run on nodes with
specific taints, or to prevent workloads from running on nodes with specific taints.

## Values

<!-- textlint-disable terminology -->
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
      - key: protected-node
        effect: NoSchedule
        operator: Exists
  node-exporter:
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists
  windows-exporter:
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists
  opencost:
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists

  kepler:
    enabled: true
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists

autoInstrumentation:
  enabled: true
  spanMetricsOnly: true
  beyla:
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists

podLogs:
  enabled: true

alloy-metrics:
  enabled: true
  controller:
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists

alloy-logs:
  enabled: true
  controller:
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists

alloy-operator:
  tolerations:
    - key: protected-node
      effect: NoSchedule
      operator: Exists

  waitForAlloyRemoval:
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists
```
<!-- textlint-enable terminology -->
