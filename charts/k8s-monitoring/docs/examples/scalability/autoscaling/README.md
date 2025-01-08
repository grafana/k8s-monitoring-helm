<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Autoscaling Example

This example shows how to configure autoscaling for the Alloy collector. This allows the Allow instance to scale up and
down based on its CPU and memory utilization.

## Values

```yaml
---
cluster:
  name: autoscaling-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true

alloy-metrics:
  enabled: true
  alloy:
    resources:
      requests:
        cpu: "1m"
        memory: "500Mi"
  controller:
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 10
      targetCPUUtilizationPercentage: 0
      targetMemoryUtilizationPercentage: 80
```
