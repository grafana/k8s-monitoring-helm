<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/cluster-metrics/control-plane-monitoring/values.yaml

## Values

```yaml
---
cluster:
  name: cluster-metrics-cluster

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

clusterMetrics:
  enabled: true
  controlPlane:
    enabled: true

podLogs:
  enabled: true

integrations:
  etcd:
    instances:
      - name: k8s-controlplane-etcd

# Collectors
alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true

alloy-singleton:
  enabled: true
```
