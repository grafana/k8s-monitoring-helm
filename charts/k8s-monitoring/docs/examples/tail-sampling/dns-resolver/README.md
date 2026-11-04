<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Tail Sampling - DNS Resolver

This example builds on the [default tail sampling example](../default), which explains how tail sampling works and why
the receiver uses an `otelcol.exporter.loadbalancing` component to route every span of a trace to the same sampler. It
changes only one thing: the resolver the load balancer uses to find the sampler pods.

## `kubernetes` (default) vs. `dns`

The default `kubernetes` resolver opens a **watch on the Kubernetes API server** for the samplers' EndpointSlices, so it
learns about pods appearing and disappearing almost instantly. The cost is that every load balancer holds an open watch.
If the Alloy instance receiving the application traces has many replicas, this can lead to significant load on the
Kubernetes cluster's API server. On clusters where API-server audit events are billed, this watch traffic can dominate
the audit volume.

The `dns` resolver avoids the API server entirely. Instead of watching, it **periodically resolves the samplers'
headless Service DNS** (every few seconds) to the current set of pod IPs:

```yaml
processors:
  tailSampling:
    enabled: true
    loadBalancer:
      resolver: dns
```

The trade-offs compared to the default:

-   **No API-server load.** DNS lookups do not touch the Kubernetes API, so this scales cleanly to very large,
    many-node clusters.
-   **Membership updates on a poll interval.** A sampler pod that restarts or reschedules is picked up on the next DNS
    resolution rather than immediately. Traces routed to a stale address during that short window are retried.
-   **Works with any controller type.** Unlike the [static resolver](../static-resolver), `dns` does not require a
    StatefulSet — it uses whichever pod IPs the Service currently resolves to.

For DNS to return the individual sampler pod IPs (rather than a single virtual IP), the chart automatically makes the
samplers' Service **headless** (`clusterIP: None`) whenever the `dns` resolver is selected.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: tail-sampling

destinations:
  # The Alloy self-monitoring metrics (including the load balancer's backend
  # count) are scraped and written to Prometheus.
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
        loadBalancer:
          resolver: dns  # <-- The key change from the default
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
