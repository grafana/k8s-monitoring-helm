<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Integration: DCGM Exporter

This example demonstrates how to gather metrics from the
NVIDIA [NCGM Exporter](https://github.com/NVIDIA/dcgm-exporter).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: dcgm-exporter-integration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

integrations:
  dcgm-exporter:
    instances:
      - name: dcgm-exporter
        labelSelectors:
          app: nvidia-dcgm-exporter

alloy-metrics:
  enabled: true
```
<!-- textlint-enable terminology -->
