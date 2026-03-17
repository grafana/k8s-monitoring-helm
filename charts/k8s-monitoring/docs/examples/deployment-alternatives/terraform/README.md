<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: deployment-alternatives/terraform/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: terraform-test

destinations:
  localPrometheus:
    type: prometheus
    auth:
      type: basic
  localLoki:
    type: loki
    auth:
      type: basic

clusterMetrics:
  enabled: true
  collector: alloy-metrics
hostMetrics:
  enabled: true
  collector: alloy-metrics
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true
clusterEvents:
  enabled: true
  collector: alloy-singleton
podLogs:
  enabled: true
  collector: alloy-logs

collectors:
  alloy-metrics: {}
  alloy-singleton: {}
  alloy-logs: {}

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
