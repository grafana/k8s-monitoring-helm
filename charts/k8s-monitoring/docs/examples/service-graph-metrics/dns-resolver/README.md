<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Service Graph Metrics - DNS Resolver

This example builds on the [default service graph metrics example](../default), which explains how service graph metrics
are generated and why the receiver uses an `otelcol.exporter.loadbalancing` component to route every span of a trace to
the same grapher.

## `kubernetes` (default) vs. `dns`

The default `kubernetes` resolver opens a **watch on the Kubernetes API server** for the graphers' EndpointSlices, so it
learns about pods appearing and disappearing almost instantly. The cost is that every load balancer holds an open watch.
If the Alloy instance receiving the application traces has many replicas, this can lead to significant load on the
Kubernetes cluster's API server.

The `dns` resolver avoids the API server entirely. Instead of watching, it **periodically resolves the graphers'
headless Service DNS** (every few seconds) to the current set of pod IPs:

```yaml
processors:
  serviceGraphMetrics:
    enabled: true
    loadBalancer:
      resolver: dns
```

The trade-offs compared to the default:

-   **No API-server load.** DNS lookups do not touch the Kubernetes API, so this scales cleanly to very large,
    many-node clusters.
-   **Membership updates on a poll interval.** A grapher pod that restarts or reschedules is picked up on the next DNS
    resolution rather than immediately. Traces routed to a stale address during that short window are retried.
-   **Works with any controller type.** Unlike the [static resolver](../static-resolver), `dns` does not require a
    StatefulSet — it uses whichever pod IPs the Service currently resolves to.

For DNS to return the individual grapher pod IPs (rather than a single virtual IP), the chart automatically makes the
graphers' Service **headless** (`clusterIP: None`) whenever the `dns` resolver is selected.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: service-graph-metrics

destinations:
  # Service graph metrics are generated from traces, then written to Prometheus.
  - name: prometheus
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write

  # Traces are forwarded to Tempo. Enabling serviceGraphMetrics deploys a
  # dedicated Alloy instance (a StatefulSet, the "service graphers") that builds
  # service graph metrics from the traces. Because a trace's client and server
  # spans may arrive at different receiver pods, the receiver uses a load
  # balancing exporter to route every span of a given trace to the same grapher,
  # so the service graph edges are counted consistently.
  - name: tempo
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
      serviceGraphMetrics:
        enabled: true
        loadBalancer:
          resolver: dns  # <-- The key change from the default
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
  # This example is only concerned with traces (for service graph metrics), so
  # application metrics and logs are not gathered.
  metrics: {enabled: false}
  logs: {enabled: false}

# Self-monitor the receiver Alloy instance so the load balancer backend count
# (otelcol_loadbalancer_num_backends) is available in Prometheus.
integrations:
  alloy:
    instances:
      - name: alloy-receiver
        labelSelectors:
          app.kubernetes.io/instance: k8smon-alloy-receiver
        metrics:
          tuning:
            includeMetrics:
              - otelcol_loadbalancer_num_backends

# The receiver is a DaemonSet, so an application's replicas may send their spans
# to different receiver pods. No matter which pod a span arrives on, the load
# balancing exporter reassembles the whole trace on a single grapher.
alloy-receiver:
  enabled: true
  controller:
    type: daemonset
  alloy:
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP
      - name: otlp-http
        port: 4318
        targetPort: 4318
        protocol: TCP

alloy-metrics:
  enabled: true
```
<!-- textlint-enable terminology -->
