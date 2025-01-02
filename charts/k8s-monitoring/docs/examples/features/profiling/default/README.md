<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Profiling

This example demonstrates how to enable the Profiling feature to gather profiles from your Kubernetes cluster and
deliver them to Pyroscope.

## Values

```yaml
---
cluster:
  name: profiling-cluster

destinations:
  - name: pyroscope
    type: pyroscope
    url: http://pyroscope.pyroscope.svc:4040

profiling:
  enabled: true

alloy-profiles:
  enabled: true
```
