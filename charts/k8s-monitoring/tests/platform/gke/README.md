<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# GKE Standard

Standard [GKE](https://cloud.google.com/kubernetes-engine) clusters give full access to the nodes and control plane, so
the Kubernetes Monitoring chart runs with its normal configuration and no platform-specific workarounds are required.

This test exercises the full feature set on GKE, including cost metrics gathered by OpenCost, which is configured to
read back from the metrics destination.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: gke-test

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

costMetrics:
  enabled: true
  collector: alloy-metrics

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
  opencost:
    deploy: true
    metricsSource: grafana-cloud-metrics
    opencost:
      exporter:
        defaultClusterId: gke-test
      prometheus:
        external:
          url: https://prometheus-prod-13-prod-us-east-0.grafana.net/api/prom
        existingSecretName: grafana-cloud-credentials
        username_key: PROMETHEUS_USER
        password_key: PROMETHEUS_PASS
```
<!-- textlint-enable terminology -->
