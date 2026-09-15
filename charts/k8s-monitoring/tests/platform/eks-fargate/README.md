<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# EKS Fargate

AWS EKS Fargate clusters have a fully managed control plane, which reduces the management burden on the user but adds
restrictions around DaemonSets and node access. This prevents services like Node Exporter from working, and it changes
how Pod logs must be gathered, since the usual approach deploys Alloy as a DaemonSet with HostPath mounts to read the
log files off each node.

This test gathers Pod logs from Fargate nodes via the
[Kubernetes API](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.source.kubernetes/) instead, and
pins the filesystem log collector to the non-Fargate node group so the DaemonSet-based collectors have somewhere to run.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: eks-fargate-test

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
      namespace: monitoring
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
      namespace: monitoring

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

podLogsViaKubernetesApi:
  enabled: true
  collector: alloy-logs
  nodeSelectors:
    eks.amazonaws.com/compute-type: fargate

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
    alloy:
      clustering:
        name: alloy-logs
        enabled: true
    controller:
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/arch: amd64
        alpha.eksctl.io/nodegroup-name: ng-linux  # Ensure we're deploying to the non-fargate nodegroup

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
