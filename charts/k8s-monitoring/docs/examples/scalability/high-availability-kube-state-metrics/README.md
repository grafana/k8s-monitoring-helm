<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Highly Available kube-state-metrics

This example demonstrates how to deploy kube-state-metrics with multiple replicas, providing a highly available setup.
Alloy should be configured to scrape kube-state-metrics using its service, rather than by pod or endpoint, to avoid
scraping the same metrics from multiple pods.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: high-availability-kube-state-metrics

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  kube-state-metrics:
    discoveryType: service

hostMetrics:
  enabled: true
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true

alloy-metrics:
  enabled: true

telemetryServices:
  kube-state-metrics:
    deploy: true
    replicas: 2
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
