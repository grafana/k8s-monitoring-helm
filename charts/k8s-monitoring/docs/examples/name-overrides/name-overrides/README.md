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
  node-exporter:
    nameOverride: node-metric-source
    labelMatchers:
      app.kubernetes.io/name: node-metric-source
  kepler:
    enabled: true
    nameOverride: energy-metric-source
  opencost:
    enabled: true
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
