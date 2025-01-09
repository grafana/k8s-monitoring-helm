<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: scalability/sharded-kube-state-metrics/values.yaml

## Values

```yaml
cluster:
  name: sharded-kube-state-metrics

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  kube-state-metrics:
    autosharding:
      enabled: true
    replicas: 5

alloy-metrics:
  enabled: true
```
