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
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

clusterMetrics:
  enabled: true
  collector: alloy-metrics

costMetrics:
  enabled: true
  collector: alloy-metrics

hostMetrics:
  enabled: true
  collector: alloy-metrics
  energyMetrics:
    enabled: true
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true

autoInstrumentation:
  enabled: true
  collector: alloy-metrics
  spanMetricsOnly: true
  beyla:
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists

podLogs:
  enabled: true
  collector: alloy-logs

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
    controller:
      tolerations:
        - key: protected-node
          effect: NoSchedule
          operator: Exists

  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
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


telemetryServices:
  kepler:
    deploy: true
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists
  kube-state-metrics:
    deploy: true
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists
  node-exporter:
    deploy: true
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists
  windows-exporter:
    deploy: true
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists
  opencost:
    deploy: true
    metricsSource: prometheus
    tolerations:
      - key: protected-node
        effect: NoSchedule
        operator: Exists
    opencost:
      exporter:
        defaultClusterId: tolerations-example-cluster
      prometheus:
        external:
          url: http://prometheus.prometheus.svc:9090/api/v1/query
```
<!-- textlint-enable terminology -->
