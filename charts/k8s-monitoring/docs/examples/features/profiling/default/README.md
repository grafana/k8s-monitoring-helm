<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Profiles Receiver

This example demonstrates how to enable the Profiles Receiver feature to receive profiles from applicaations on your
Kubernetes cluster, process them according to defined rules, and then deliver them to Pyroscope.

## Values

<!-- textlint-disable terminology -->
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
<!-- textlint-enable terminology -->
