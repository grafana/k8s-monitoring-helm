<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Custom processor: Static Label (MLTP)

This custom processor stamps a single static label, `region = "central"`, onto **every**
telemetry type before it leaves the cluster — Metrics, Logs, Traces, and Profiles (MLTP).

A single `static-label` processor declares one pipeline per ecosystem, and four different
features opt in to it via `dataProcessors: [static-label]`:

| Telemetry | Feature                   | Ecosystem    | How the label is added                |
| --------- | ------------------------- | ------------ | ------------------------------------- |
| Metrics   | `annotationAutodiscovery` | `prometheus` | `prometheus.relabel` rule             |
| Logs      | `podLogsViaLoki`          | `loki`       | `loki.process` `stage.static_labels`  |
| Traces    | `applicationObservability`| `otlp`       | `otelcol.processor.transform`         |
| Profiles  | `profilesReceiver`        | `pyroscope`  | `pyroscope.relabel` rule              |

```text
  annotationAutodiscovery ─ metrics ─┐
  podLogsViaLoki ─────────── logs ───┤   dataProcessors.static-label
  applicationObservability ─ traces ─┤   (region = "central")      ──►  matching destination
  profilesReceiver ───────── profiles┘
```

Each feature still delivers to the destination it would have selected on its own; the chart
stamps `selected_destinations` going in and gates each destination on the way out.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: static-label

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword
  tempo:
    type: otlp
    url: tempo.tempo.svc:4317
    tls:
      insecure: true
      insecureSkipVerify: true
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}
  pyroscope:
    type: pyroscope
    url: http://pyroscope.pyroscope.svc:4040

dataProcessors:
  # A single custom processor that stamps `region = "central"` onto every telemetry type,
  # across each ecosystem the source features use (Metrics, Logs, Traces, Profiles).
  # The chart forwards data into each pipeline's `input`; each pipeline forwards to the
  # chart-generated output sink (documented name: <proc>_out_<type>_<ecosystem>).
  static-label:
    type: custom
    metrics:
      prometheus:
        enabled: true
        input: prometheus.relabel.static_label_metrics.receiver
        config: |
          prometheus.relabel "static_label_metrics" {
            rule {
              target_label = "region"
              replacement  = "central"
            }
            forward_to = [prometheus.relabel.static_label_out_metrics_prometheus.receiver]
          }
    logs:
      loki:
        enabled: true
        input: loki.process.static_label_logs.receiver
        config: |
          loki.process "static_label_logs" {
            stage.static_labels {
              values = {
                region = "central",
              }
            }
            forward_to = [loki.process.static_label_out_logs_loki.receiver]
          }
    traces:
      otlp:
        enabled: true
        input: otelcol.processor.transform.static_label_traces.input
        config: |
          otelcol.processor.transform "static_label_traces" {
            error_mode = "ignore"
            trace_statements {
              context = "resource"
              statements = [
                "set(attributes[\"region\"], \"central\")",
              ]
            }
            output {
              traces = [otelcol.processor.batch.static_label_out_traces_otlp.input]
            }
          }
    profiles:
      pyroscope:
        enabled: true
        input: pyroscope.relabel.static_label_profiles.receiver
        config: |
          pyroscope.relabel "static_label_profiles" {
            rule {
              target_label = "region"
              replacement  = "central"
            }
            forward_to = [pyroscope.relabel.static_label_out_profiles_pyroscope.receiver]
          }

# Metrics
annotationAutodiscovery:
  enabled: true
  collector: alloy-metrics
  dataProcessors: [static-label]

# Logs
podLogsViaLoki:
  enabled: true
  collector: alloy-logs
  dataProcessors: [static-label]

# Traces
applicationObservability:
  enabled: true
  collector: alloy-receiver
  dataProcessors: [static-label]
  metrics: {enabled: false}
  logs: {enabled: false}
  traces: {enabled: true}
  receivers:
    otlp:
      grpc:
        enabled: true

# Profiles
profilesReceiver:
  enabled: true
  collector: alloy-receiver
  dataProcessors: [static-label]

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
  alloy-receiver:
    presets: [deployment]
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
