<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Node Labels

This example shows how to include node labels on all jobs for nodes, pods and endpoints.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: pod-labels-and-annotations

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push
  - name: tempo
    type: otlp
    url: http://tempo.tempo.svc
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

clusterMetrics:
  enabled: true
  nodeLabels:
    nodePool: true
    region: true
    availabilityZone: true
    nodeRole: true
    os: true
    architecture: true
    instanceType: true

podLogs:
  enabled: true
  nodeLabels:
    nodepool: true
    region: true
    availability_zone: true
    node_role: true
    os: true
    architecture: true
    instance_type: true
  structuredMetadata:
    node_pool: nodepool
    region:
    availability_zone:
    node_role:
    node_os: os
    node_arch: architecture
    node_type: instance_type

annotationAutodiscovery:
  nodeLabels:
    nodePool: true
    region: true
    availabilityZone: true
    nodeRole: true
    os: true
    architecture: true
    instanceType: true
  enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
