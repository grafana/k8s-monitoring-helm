<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# KEDA Autoscaling Example

This example shows how to use [KEDA](https://keda.sh/) to autoscale the Alloy collector based on Alloy's own
custom metric `prometheus_remote_write_wal_storage_active_series`. This metric tracks the number of active
series Alloy is buffering in its write-ahead log on the way to the Prometheus destination, and is a better
signal of telemetry workload than CPU or memory alone.

The Alloy integration is enabled so Alloy scrapes its own metrics and ships them to Prometheus, where KEDA
queries them through a Prometheus trigger on a `ScaledObject`. The native Alloy autoscaling is not used
because KEDA creates and manages its own HorizontalPodAutoscaler.

## Prerequisites

KEDA must be installed in the cluster. See the
[KEDA installation guide](https://keda.sh/docs/latest/deploy/).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: keda-autoscaling-example-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  collector: alloy-metrics

# Scrape Alloy's own metrics so they are available in Prometheus for KEDA to query.
integrations:
  collector: alloy-metrics
  alloy:
    instances:
      - name: alloy-metrics
        labelSelectors:
          app.kubernetes.io/name: alloy-metrics

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
    alloy:
      resources:
        requests:
          cpu: "1m"
          memory: "500Mi"
    # Native HPA is intentionally disabled. KEDA's ScaledObject below creates and manages an HPA
    # that scales on Alloy's own custom metric (active series in the Prometheus remote_write WAL).
    controller:
      autoscaling:
        enabled: false

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true

# KEDA must be installed in the cluster for the ScaledObject below to take effect.
# See https://keda.sh/docs/latest/deploy/ for installation instructions.
extraObjects:
  - apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: alloy-metrics
      namespace: default
    spec:
      scaleTargetRef:
        kind: StatefulSet
        name: k8smon-alloy-metrics
      minReplicaCount: 1
      maxReplicaCount: 10
      pollingInterval: 30
      cooldownPeriod: 300
      triggers:
        - type: prometheus
          metadata:
            serverAddress: http://prometheus-server.prometheus.svc:9090
            threshold: "100000"
            query: |
              avg(prometheus_remote_write_wal_storage_active_series{cluster="keda-autoscaling-example-cluster", job="integrations/alloy"})
```
<!-- textlint-enable terminology -->
