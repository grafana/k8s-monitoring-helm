<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/cluster-metrics/default/values.yaml

## Values

```yaml
---
cluster:
  name: cluster-metrics-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  kepler:
    enabled: true
  opencost:
    enabled: true
    metricsSource: prometheus
    opencost:
      exporter:
        defaultClusterId: cluster-metrics-example-cluster
      prometheus:
        external:
          url: http://prometheus.prometheus.svc:9090/api/v1/query

alloy-metrics:
  enabled: true
```
