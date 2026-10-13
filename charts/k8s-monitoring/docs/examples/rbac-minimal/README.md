<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# RBAC: Minimal

This example sets `rbac.mode: minimal` for every collector. Instead of the Alloy Operator creating the same broad
ClusterRole for each collector, this chart renders RBAC objects that only grant what each collector's configuration
needs:

*   `alloy-metrics` gets a ClusterRole to discover Nodes and scrape the kubelet, plus a Role in the release namespace to
    discover kube-state-metrics and Node Exporter, and to read the Prometheus credentials Secret.
*   `alloy-singleton` gets a ClusterRole to read Events, plus a Role to read the destination credentials Secrets.
*   `alloy-logs` gets a ClusterRole to discover Pods, plus a Role to read the Loki credentials Secret.

For more information, see [RBAC](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/RBAC.md).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: rbac-minimal

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
    auth:
      type: basic
      username: promuser
      password: prometheuspassword
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

clusterMetrics:
  enabled: true
  collector: alloy-metrics

hostMetrics:
  enabled: true
  collector: alloy-metrics
  linuxHosts:
    enabled: true

clusterEvents:
  enabled: true
  collector: alloy-singleton

podLogsViaLoki:
  enabled: true
  collector: alloy-logs

collectorCommon:
  alloy:
    rbac:
      mode: minimal

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
  alloy-singleton:
    presets: [singleton]
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
