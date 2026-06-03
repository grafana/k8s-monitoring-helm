<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Linux Host Metrics via Alloy

This example demonstrates how to collect Linux host metrics directly with Alloy, using the built-in
`prometheus.exporter.unix` component instead of scraping a separate Node Exporter deployment. Setting
`hostMetrics.linuxHosts.source: alloy` requires the assigned collector to be a privileged DaemonSet that
mounts the host filesystem, which is configured here with the `linux-host-monitor` collector preset.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: host-metrics-example-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write

hostMetrics:
  enabled: true
  linuxHosts:
    enabled: true
    # Collect Linux host metrics directly with Alloy, instead of scraping a Node Exporter deployment.
    source: alloy

collectors:
  alloy-metrics:
    # The linux-host-monitor preset grants the privileges and host mounts needed to collect host metrics via
    # prometheus.exporter.unix; the daemonset preset runs the collector on every node.
    presets: [linux-host-monitor, daemonset]
```
<!-- textlint-enable terminology -->
