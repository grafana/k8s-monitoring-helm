<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Self Reporting


## Values

```yaml
cluster:
  name: self-reporting-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

# Features
clusterEvents:
  enabled: true

alloy-singleton:
  enabled: true
```
