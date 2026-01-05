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
  name: prometheus-operator-objects-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

prometheusOperatorObjects:
  enabled: true

  podMonitors:
    labelSelectors:
      app.kubernetes.io/name: my-app

  serviceMonitors:
    namespaces:
      - development
      - staging
      - production
    labelExpressions:
      - key: preview-build
        operator: DoesNotExist
      - key: app.kubernetes.io/name
        operator: In
        values:
          - my-app
          - my-other-app

alloy-metrics:
  enabled: true
```
<!-- textlint-enable terminology -->
