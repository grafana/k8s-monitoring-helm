<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Custom processor: Scrub Log PII

This custom processor scrubs email addresses out of log lines before they leave the cluster.
It demonstrates how a single processor can handle both Loki-formatted and OTLP-formatted logs:
`podLogsViaLoki` produces Loki records and `podLogsViaOpenTelemetry` produces OTLP records.
Each feature opts in to the same processor via `dataProcessors: [scrub-pii]`.

After the processor runs, the chart fans the data back out to the destinations each feature
would have selected on its own — the Loki path to the `loki` destination, the OTLP path to the
`loki-otlp` destination.

```text
                                          dataProcessors.scrub-pii
                                ┌──────────────────────────────────────┐
                                │                                      │
  podLogsViaLoki ───── Loki ──► │  loki.process "scrub_pii_loki"       │ ──► loki (destination)
   (Loki logs)                  │  (stage.replace email → [REDACTED])  │
                                │                                      │
                                │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
                                │                                      │
  podLogsViaOpenTelemetry ─ OTLP ─► otelcol.processor.transform        │ ──► loki-otlp
   (OTLP logs)                  │  "scrub_pii_otlp"                    │       (destination)
                                │  (replace_pattern body email → ...)  │
                                │                                      │
                                └──────────────────────────────────────┘
                                    chart stamps `selected_destinations`
                                    on the way in, gates each destination
                                    on the way out
```

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: scrub-log-pii

destinations:
  # Loki-ecosystem destination. Receives the Loki-formatted logs from podLogsViaLoki.
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

  # OTLP-ecosystem destination, pointed at Loki's OTLP endpoint. Receives the
  # OTLP-formatted logs from podLogsViaOpenTelemetry.
  loki-otlp:
    type: otlp
    protocol: http
    url: http://loki.loki.svc:3100/otlp
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword
    metrics: {enabled: false}
    logs: {enabled: true}
    traces: {enabled: false}

dataProcessors:
  # A single custom processor that scrubs email addresses out of log records, in BOTH
  # Loki and OTLP form. The chart forwards data into each pipeline's `input` and the
  # pipeline forwards its result to the chart-generated output sink (documented name).
  scrub-pii:
    type: custom
    logs:
      loki:
        enabled: true
        input: loki.process.scrub_pii_loki.receiver
        config: |
          loki.process "scrub_pii_loki" {
            stage.replace {
              expression = "([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,})"
              replace    = "[REDACTED-EMAIL]"
            }
            forward_to = [loki.process.scrub_pii_out_logs_loki.receiver]
          }
      otlp:
        enabled: true
        input: otelcol.processor.transform.scrub_pii_otlp.input
        config: |
          otelcol.processor.transform "scrub_pii_otlp" {
            error_mode = "ignore"
            log_statements {
              context = "log"
              statements = [
                "replace_pattern(body, \"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{2,}\", \"[REDACTED-EMAIL]\")",
              ]
            }
            output {
              logs = [otelcol.processor.batch.scrub_pii_out_logs_otlp.input]
            }
          }

# Loki-formatted pod logs, scrubbed, delivered to the Loki destination.
podLogsViaLoki:
  enabled: true
  namespaces: [workload]

  collector: alloy-logs
  dataProcessors: [scrub-pii]

# OTLP-formatted pod logs, scrubbed, delivered to the OTLP destination.
podLogsViaOpenTelemetry:
  enabled: true
  namespaces: [workload]

  collector: alloy-logs
  dataProcessors: [scrub-pii]

collectors:
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
    alloy:
      stabilityLevel: public-preview
    liveDebugging:
      enabled: true
```
<!-- textlint-enable terminology -->
