<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# GPU

On clusters with NVIDIA GPUs, the
[NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html) deploys the
[DCGM Exporter](https://github.com/NVIDIA/dcgm-exporter), which exposes GPU metrics such as utilization, memory usage,
temperature, and power draw.

This test uses the `dcgm-exporter` integration to discover and scrape those exporter pods so the GPU metrics are
collected and sent to the metrics destination.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: gpu-test

destinations:
  grafana-cloud-metrics:
    type: prometheus
    url: https://prometheus-prod-13-prod-us-east-0.grafana.net./api/prom/push
    auth:
      type: basic
      usernameKey: PROMETHEUS_USER
      passwordKey: PROMETHEUS_PASS
    secret:
      create: false
      name: grafana-cloud-credentials
      namespace: default

clusterMetrics:
  enabled: true
  collector: alloy-metrics

hostMetrics:
  enabled: true
  collector: alloy-metrics
  linuxHosts:
    enabled: true

integrations:
  collector: alloy-metrics
  dcgm-exporter:
    instances:
      - name: dcgm-exporter
        labelSelectors:
          app: nvidia-dcgm-exporter

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
