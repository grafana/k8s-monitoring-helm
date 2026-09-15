<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# GKE Autopilot

Fully managed clusters like [GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
need extra consideration because they restrict DaemonSets and node access. This prevents services like Node Exporter
from working, so this test does not deploy it. Missing Node Exporter metrics is generally fine, because the health of
the nodes is the cloud provider's responsibility, not the user's.

Autopilot also does not expose the Docker container directory on its nodes, so the log collector disables the
`dockercontainers` mount.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: gke-autopilot-test

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
    alloy:
      mounts:
        dockercontainers: false

telemetryServices:
  kube-state-metrics:
    deploy: true
```
<!-- textlint-enable terminology -->
