<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Tail Sampling

This example shows how to configure tail sampling for traces with the k8s-monitoring Helm chart.

## What is tail sampling?

With **head** sampling, the keep-or-drop decision is made when a trace starts, before anything is known about how it
turns out. **Tail** sampling instead waits until all of a trace's spans have been collected and then decides, so the
decision can be based on the complete trace. That makes it possible to:

-   Keep every trace that contains an error, regardless of how long it took.
-   Keep traces that ran slower than some latency threshold.
-   Make decisions based on attributes found anywhere in the trace.
-   Combine several conditions with `and`/`or` logic.
-   Sample a percentage of everything else to keep the volume down.

## How it works

Enabling `tailSampling` on an OTLP destination deploys a dedicated Alloy instance (a StatefulSet, the "samplers") that
runs the [`otelcol.processor.tail_sampling`](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.tail_sampling/)
component. The traces sent to the destination are forwarded to the samplers, which apply the policies and then forward
the traces that are kept on to the trace destination (Tempo, in this example).

Because tail sampling decides over a whole trace, **every span of a trace must land on the same sampler**. If a trace's
spans were spread across several samplers, each would decide on a partial trace and the policies would misfire. To keep
each trace whole, the receiver forwards traces through an
[`otelcol.exporter.loadbalancing`](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.exporter.loadbalancing/)
component, which consistently routes every span of a given trace ID to the same sampler.

This matters most when the receiver is scaled out. In this example the receiver is a **DaemonSet**, so an application's
replicas may send their spans to different replicas of the receiver. No matter which receiver pod a span arrives on, the
load balancing exporter ensures the whole trace is reassembled on a single sampler:

```text
  workload replicas (many nodes)
        │  OTLP
        ▼
  alloy (DaemonSet: one pod per node)
        │  loadbalancing exporter — routes by trace ID
        ▼
  samplers (StatefulSet: 3 replicas)
        │  tail sampling policies applied
        ▼
  Tempo
```

## Sampling policies

The policies are set under `processors.tailSampling.policies`. This example keeps a couple of representative ones:

```yaml
processors:
  tailSampling:
    enabled: true
    policies:
      # Keep every trace that contains an error.
      - name: keep-errors
        type: status_code
        status_codes: [ERROR]
      # Sample 15% of everything else.
      - name: sample-15pct
        type: probabilistic
        sampling_percentage: 15
```

The [`otelcol.processor.tail_sampling` reference](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.tail_sampling/)
lists every policy type and its options, along with `and`/`or` composite policies for combining conditions.

## Choosing a resolver

The load balancing exporter has to know which sampler pods exist. How it discovers them is the **resolver**, set with
`processors.tailSampling.loadBalancer.resolver`. This example uses the default, `kubernetes`, which opens a watch on the
Kubernetes API server for the samplers' EndpointSlices. Two other resolvers trade that API-server load for slightly
different behavior:

-   [`dns`](../dns-resolver) — periodically resolves the samplers' headless Service DNS to the pod IPs.
-   [`static`](../static-resolver) — addresses each pod by its stable, ordinal StatefulSet hostname, with no discovery
    at all.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: tail-sampling

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write

  # Traces are forwarded to Tempo. Enabling tailSampling deploys a dedicated
  # Alloy instance (a StatefulSet, the "samplers") that applies the tail
  # sampling policies before the traces are written to Tempo. Because a trace's
  # spans may arrive at different receiver pods, the receiver uses a load
  # balancing exporter to route every span of a given trace to the same sampler,
  # so the sampling decision is made over the whole trace.
  tempo:
    type: otlp
    url: http://tempo.tempo.svc:4317
    tls:
      insecure: true
      insecureSkipVerify: true
    metrics:
      enabled: false
    logs:
      enabled: false
    traces:
      enabled: true
    processors:
      tailSampling:
        enabled: true
        policies:
          # Keep every trace that contains an error.
          - name: keep-errors
            type: status_code
            status_codes: [ERROR]
          # Sample 15% of everything else.
          - name: sample-15pct
            type: probabilistic
            sampling_percentage: 15
        collector:
          controller:
            replicas: 3

applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true
      http:
        enabled: true
  metrics: {enabled: false}
  logs: {enabled: false}

integrations:
  alloy:
    instances:
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: alloy
          app.kubernetes.io/instance: k8smon-alloy
        metrics:
          tuning:
            includeMetrics:
              - otelcol_loadbalancer_num_backends

collectors:
  alloy:
    presets: [daemonset]
```
<!-- textlint-enable terminology -->
