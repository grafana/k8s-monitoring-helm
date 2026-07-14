<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# No-op (null) Destination Example

This example demonstrates how to use the `nop` destination. A `nop` destination accepts metrics, logs, traces, and
profiles and drops all of it — nothing is stored or forwarded anywhere. Each signal terminates at a dead-end Alloy
component (for example `prometheus.relabel` and `loki.relabel` with an empty `forward_to`, `otelcol.connector.spanlogs`
with an empty `output`, and `pyroscope.relabel` with an empty `forward_to`).

This is useful for measuring how much telemetry a deployment produces before committing to real backends. Deploy with
only a `nop` destination, read the volume from Alloy's own metrics, tune your configuration, and then replace the `nop`
destination with real ones. Individual signals can be turned off with, for example, `traces: {enabled: false}`.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: nop-destination-test

destinations:
  # A no-op destination accepts every signal and drops it. Because it is the only
  # destination defined, all enabled features send their data here and nothing is
  # stored or forwarded anywhere. Use this to measure telemetry volume from Alloy's
  # own metrics before committing to real destinations, then swap this out.
  dev-null:
    type: nop

# Metrics
clusterMetrics:
  enabled: true
  collector: alloy-metrics

# Logs
podLogsViaLoki:
  enabled: true
  collector: alloy-logs

# Traces (plus application metrics and logs)
applicationObservability:
  enabled: true
  collector: alloy-receiver
  receivers:
    otlp:
      grpc:
        enabled: true

# Profiles
profilesReceiver:
  enabled: true
  collector: alloy-receiver

telemetryServices:
  kube-state-metrics:
    deploy: true

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]

  alloy-logs:
    presets: [filesystem-log-reader, daemonset]

  alloy-receiver:
    alloy:
      extraPorts:
        - name: otlp-grpc
          port: 4317
          targetPort: 4317
          protocol: TCP
        - name: profiles
          port: 4040
          targetPort: 4040
          protocol: TCP
```
<!-- textlint-enable terminology -->
