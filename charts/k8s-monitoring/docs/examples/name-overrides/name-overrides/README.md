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
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  collector: alloy-metrics

costMetrics:
  enabled: true
  collector: alloy-metrics
  opencost:
    labelMatchers:
      app.kubernetes.io/name: cost-metric-source

hostMetrics:
  enabled: true
  collector: alloy-metrics
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

collectors:
  alloy-metrics:
    nameOverride: metric-collector

```
<!-- textlint-enable terminology -->
