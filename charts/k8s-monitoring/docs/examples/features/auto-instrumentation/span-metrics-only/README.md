<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: Auto-Instrumentation with Span Metrics Only

This example demonstrates how to use Beyla for automatic instrumentation while collecting only span metrics (RED metrics) without exporting full distributed traces.

## Use Case

This configuration is useful when you want:

*   **Metrics from auto-instrumented applications** (request rate, error rate, duration)
*   **Service graph metrics** showing relationships between services
*   **Lower data volume** by avoiding full trace exports
*   **Cost optimization** when trace storage is expensive

## How It Works

When `spanMetricsOnly: true` is set:

1.  Beyla automatically instruments applications using eBPF
2.  Beyla generates span metrics (RED metrics) from HTTP/gRPC calls
3.  Metrics are scraped by Alloy and sent to Prometheus
4.  **Full trace spans are NOT sent** to the OTLP receiver, even though Application Observability is enabled

## When to Use This

Choose `spanMetricsOnly: true` when:

*   You want observability without trace storage costs
*   You need RED metrics but not detailed trace analysis
*   You're instrumenting high-throughput services where full tracing would be too expensive
*   You already have tracing from other sources and only need Beyla for metrics

## Alternative

If you need full traces from Beyla, set `spanMetricsOnly: false` (the default) or omit the field entirely. See the [beyla-metrics-and-traces example](../beyla-metrics-and-traces/) for that configuration.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: span-metrics-only-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.monitoring.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.logging.svc:3100/loki/api/v1/push
  - name: tempo
    type: otlp
    url: http://tempo.tracing.svc:4317
    tls:
      insecure: true
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

# Enable Application Observability with OTLP receiver
# This would normally cause Beyla to export full traces
applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true

# Enable Auto-Instrumentation with span metrics only
# This prevents Beyla from sending traces to the OTLP receiver
# Beyla will still generate span metrics (RED metrics) and send them to Prometheus
autoInstrumentation:
  enabled: true
  beyla:
    deliverTracesToApplicationObservability: false  # Only collect span metrics, do not export traces

alloy-metrics:
  enabled: true

alloy-receiver:
  enabled: true
  alloy:
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP
```
<!-- textlint-enable terminology -->
