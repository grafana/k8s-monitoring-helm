<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: name-overrides/fullname-overrides/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: fullname-override-test


destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true

costMetrics:
  enabled: true
  opencost:
    labelMatchers:
      app.kubernetes.io/name: cost-metric-source

hostMetrics:
  enabled: true
  linuxHosts:
    enabled: true
    labelMatchers:
      app.kubernetes.io/name: node-metric-source
  energyMetrics:
    enabled: true
    labelMatchers:
      app.kubernetes.io/name: energy-metric-source

alloy-metrics:
  enabled: true
  fullnameOverride: metric-collector

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
    fullnameOverride: node-metric-source
  kepler:
    deploy: true
    fullnameOverride: energy-metric-source
  opencost:
    deploy: true
    fullnameOverride: cost-metric-source
    metricsSource: prometheus
    opencost:
      exporter:
        defaultClusterId: fullname-override-test
      prometheus:
        external:
          url: http://prometheus.prometheus.svc:9090/api/v1/query
```
<!-- textlint-enable terminology -->
