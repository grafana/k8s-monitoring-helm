<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: name-overrides/name-overrides/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: name-override-test


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
  energyMetrics:
    enabled: true
    labelMatchers:
      app.kubernetes.io/name: energy-metric-source
  linuxHosts:
    labelMatchers:
      app.kubernetes.io/name: node-metric-source

telemetryServices:
  kube-state-metrics:
    deploy: true
  kepler:
    deploy: true
    nameOverride: energy-metric-source
  node-exporter:
    deploy: true
    nameOverride: node-metric-source
  opencost:
    deploy: true
    nameOverride: cost-metric-source
    metricsSource: prometheus
    opencost:
      exporter:
        defaultClusterId: name-override-test
      prometheus:
        external:
          url: http://prometheus.prometheus.svc:9090/api/v1/query

alloy-metrics:
  enabled: true
  nameOverride: metric-collector
```
<!-- textlint-enable terminology -->
