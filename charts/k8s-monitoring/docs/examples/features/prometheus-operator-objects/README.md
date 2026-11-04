<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Prometheus Operator Objects

This example demonstrates how to enable the Prometheus Operator Objects feature to discover and gather metrics from
PodMonitors, Probes, ScrapeConfigs, and ServiceMonitors in your Kubernetes cluster.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: prom-operator-objects-cluster

destinations:
  localPrometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write

prometheusOperatorObjects:
  enabled: true

  serviceMonitors:
    enabled: true
    excludeNamespaces: [default]

    labelSelectors:
      app.kubernetes.io/name: grafana

  podMonitors:
    enabled: true
    namespaces: ["nginx", "nginx-.*"]
    extraDiscoveryRules: |
      rule {
        source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
        target_label = "service_name"
      }

  probes:
    enabled: true
    namespaces: []  # Find Probes in all namespaces

  scrapeConfigs:
    enabled: true
    namespaces: [default]

collectors:
  alloy:
    presets: [clustered, statefulset]
    alloy:
      stabilityLevel: experimental
```
<!-- textlint-enable terminology -->
