<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Cluster Events with Clustering

This example demonstrates how to run the Cluster Events feature on a clustered collector with multiple replicas.
With `clusterEvents.clustering: true`, the assigned collector must have Alloy clustering enabled, and event watching is
sharded across the cluster peers so events are not duplicated when the collector is scaled up.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: cluster-events-clustered-cluster

destinations:
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

clusterEvents:
  enabled: true
  clustering: true
  collector: alloy-events

collectors:
  alloy-events:
    presets: [clustered, deployment]
    controller:
      replicas: 2
```
<!-- textlint-enable terminology -->
