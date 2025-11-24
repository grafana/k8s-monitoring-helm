<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Custom Destination: Debug

This custom destination shows how to configure a debug destination that emits debugging information to Alloy's
pod logs.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: debug-custom-destination

destinations:
  - name: debug
    type: custom
    config: |
      otelcol.exporter.debug "default" {
        verbosity = "detailed"
      }
    ecosystem: otlp
    metrics:
      enabled: true
      target: otelcol.exporter.debug.default.input
    logs:
      enabled: true
      target: otelcol.exporter.debug.default.input
    traces:
      enabled: true
      target: otelcol.exporter.debug.default.input

annotationAutodiscovery:
  enabled: true
  destinations: [debug]
  metricsTuning:
    includeMetrics: [alloy_build_info]

alloy-metrics:
  enabled: true
  alloy:
    stabilityLevel: experimental
  controller:
    podAnnotations:
      k8s.grafana.com/scrape: "true"
      k8s.grafana.com/metrics.container: alloy
```
<!-- textlint-enable terminology -->
