<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Annotation-based autodiscovery using Prometheus Annotations

This example shows how to enable the annotation-based autodiscovery feature using Prometheus-style annotations.

## Values

```yaml
---
cluster:
  name: annotation-autodiscovery-prom-annotations-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

annotationAutodiscovery:
  enabled: true

alloy-metrics:
  enabled: true
  annotations:
    scrape: prometheus.io/scrape
    metricsPath: prometheus.io/path
    metricsPortNumber: prometheus.io/port
```
