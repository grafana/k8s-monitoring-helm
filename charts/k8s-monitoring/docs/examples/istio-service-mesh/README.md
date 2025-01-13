<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Istio Service Mesh example

This example shows how to ensure that Alloy clustering when Istio Service Mesh is enabled and has deployed the Istio
sidecar to the Alloy pods. This change is necessary because the Alloy cluster's headless Service port name
[will not work](https://istio.io/latest/docs/ops/common-problems/network-issues/#503-error-while-accessing-headless-services)
if it keeps its default port name of `http`.

## Values

```yaml
---
cluster:
  name: istio-service-mesh-example

destinations:
  - name: localPrometheus
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write

annotationAutodiscovery:
  enabled: true
  annotations:
    scrape: prometheus.io/scrape
    metricsPath: prometheus.io/path
    metricsPortNumber: prometheus.io/port

clusterMetrics:
  enabled: true

alloy-metrics:
  enabled: true
  alloy:
    clustering:
      portName: tcp
  controller:
    replicas: 2
```
