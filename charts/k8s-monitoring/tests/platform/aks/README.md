<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Azure AKS

In certain Azure AKS cluster configurations, pods running outside the `kube-system` namespace are blocked from reaching
the Kubernetes API server. Setting the `kubernetes.azure.com/set-kube-service-host-fqdn` annotation lets an admission
controller already present in the cluster inject the configuration those pods need to reach the API server. This is
required for the Alloy collectors, which use the API server to discover targets, secrets, and configuration, and for
kube-state-metrics, which uses it to build metrics about the objects in the cluster.

This test applies that annotation to the collectors and to kube-state-metrics, and deploys both Node Exporter and
Windows Exporter to gather host metrics from the Linux and Windows nodes in the cluster.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: aks-test

destinations:
  grafana-cloud-metrics:
    type: prometheus
    url: https://prometheus-prod-13-prod-us-east-0.grafana.net/api/prom/push
    auth:
      type: basic
      usernameKey: PROMETHEUS_USER
      passwordKey: PROMETHEUS_PASS
    secret:
      create: false
      name: grafana-cloud-credentials
      namespace: default
  grafana-cloud-logs:
    type: loki
    url: https://logs-prod-006.grafana.net/loki/api/v1/push
    auth:
      type: basic
      usernameKey: LOKI_USER
      passwordKey: LOKI_PASS
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
  windowsHosts:
    enabled: true

clusterEvents:
  enabled: true
  collector: alloy-singleton

podLogsViaLoki:
  enabled: true
  collector: alloy-logs

integrations:
  collector: alloy-metrics
  alloy:
    instances:
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: [alloy-metrics, alloy-singleton, alloy-logs]

collectorCommon:
  alloy:
    controller:
      podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}

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
    podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
