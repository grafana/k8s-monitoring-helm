<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
<!--alex disable host-hostess hostesses-hosts -->
# EKS with Alloy on Windows nodes

This cluster has both Linux and Windows nodes. Rather than deploying a separate Windows Exporter, Alloy runs as a
DaemonSet on the Windows nodes and collects Windows host metrics with its built-in `prometheus.exporter.windows` and
Windows Event Logs with `loki.source.windowsevent`. A second Linux Alloy DaemonSet handles the rest of the telemetry.

Because a Windows Alloy pod cannot mount host log files the way a Linux pod can, Pod logs from the Windows nodes are
gathered via the Kubernetes API instead of from the node filesystem.

The Windows collector uses the `windows`, `windows-host-process`, and `windows-scrapeable` presets. The last opens the
host firewall so the Linux collector can scrape the Windows collector's metrics over the host network. This test also
demonstrates enriching telemetry with EC2 instance tags, which requires Alloy's `experimental` stability level.
<!--alex enable host-hostess hostesses-hosts -->

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: eks-alloy-on-windows-test

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

dataProcessors:
  # Copies the EC2 instance `Team` tag onto telemetry, matching each node's `node` label to
  # its instance private DNS name via discovery.ec2.
  ec2-tags:
    type: ec2Enrichment
    region: ap-northeast-2
    tags:
      team: Team

clusterMetrics:
  enabled: true
  collector: alloy-linux
  dataProcessors: [ec2-tags]

hostMetrics:
  enabled: true
  collector: alloy-linux
  linuxHosts:
    enabled: true
    source: alloy
  windowsHosts:
    enabled: true
    # Collect Windows host metrics with the Alloy DaemonSet running on the Windows nodes, using the
    # built-in prometheus.exporter.windows, instead of deploying and scraping a separate Windows Exporter.
    source: alloy
    collector: alloy-windows
  energyMetrics:
    enabled: true

clusterEvents:
  enabled: true
  clustering: true
  collector: alloy-linux

nodeLogs:
  enabled: true
  collector: alloy-linux

windowsEventLogs:
  enabled: true
  collector: alloy-windows
  sources:
    - name: application
      eventLogName: Application
      jobLabel: integrations/windows-application-logs
    - name: system
      eventLogName: System
      jobLabel: integrations/windows-system-logs

podLogsViaLoki:
  enabled: true
  collector: alloy-linux

podLogsViaKubernetesApi:
  enabled: true
  collector: alloy-linux
  nodeSelector:
    kubernetes.io/os: windows

integrations:
  collector: alloy-linux
  alloy:
    instances:
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: [alloy-linux, alloy-windows]

collectors:
  alloy-linux:
    presets: [clustered, linux-host-monitor, filesystem-log-reader, daemonset]
    alloy:
      stabilityLevel: experimental  # Required for prometheus.enrich (ec2Enrichment processor)

  alloy-windows:
    # `windows-scrapeable` opens the host firewall so alloy-linux can scrape this collector's metrics over hostNetwork.
    presets: [windows, windows-host-process, windows-scrapeable, daemonset]
    alloy:
      stabilityLevel: experimental  # Required for prometheus.enrich (ec2Enrichment processor)

telemetryServices:
  kube-state-metrics:
    deploy: true
  kepler:
    deploy: true
```
<!-- textlint-enable terminology -->
