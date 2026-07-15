<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Service Graph Metrics - Static Resolver

This example builds on the [default service graph metrics example](../default), which explains how service graph metrics
are generated and why the receiver uses an `otelcol.exporter.loadbalancing` component to route every span of a trace to
the same grapher.

## `kubernetes` (default) vs. `static`

The default `kubernetes` resolver opens a **watch on the Kubernetes API server** for the graphers' EndpointSlices, so it
learns about pods appearing and disappearing almost instantly. The cost is that every load balancer holds an open watch.
If the Alloy instance receiving the application traces has many replicas, this can lead to significant load on the
Kubernetes cluster's API server.

The `static` resolver does no discovery at all. The grapher must run as a StatefulSet, which gives each pod a stable,
ordinal hostname (`...-0`, `...-1`, ...), so the chart can compute the **complete list of backends ahead of time** from
the configured replica count and bake it straight into the config:

```yaml
processors:
  serviceGraphMetrics:
    enabled: true
    loadBalancerResolver: static
    collector:
      controller:
        type: statefulset  # required by the static resolver
        replicas: 3
```

The trade-offs compared to the default:

-   **No API-server load and no DNS polling for membership.** The backend list is fixed, so there is nothing to watch or
    re-resolve. This is the lightest-weight option on very large clusters.
-   **Requires a StatefulSet.** The resolver addresses each pod by its ordinal hostname, which only a StatefulSet
    provides.
-   **The replica count is fixed at deploy time.** The backend list is generated from `collector.controller.replicas`,
    so changing the number of graphers requires a `helm upgrade` to regenerate it. The resolver will not pick up pods
    added or removed out of band.

So that the ordinal hostnames resolve, the chart automatically makes the graphers' Service **headless**
(`clusterIP: None`) whenever the `static` resolver is selected.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: service-graph-metrics

destinations:
  # Service graph metrics are generated from traces, then written to Prometheus.
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write

  # Traces are forwarded to Tempo. Enabling serviceGraphMetrics deploys a
  # dedicated Alloy instance (a StatefulSet, the "service graphers") that builds
  # service graph metrics from the traces. Because a trace's client and server
  # spans may arrive at different receiver pods, the receiver uses a load
  # balancing exporter to route every span of a given trace to the same grapher,
  # so the service graph edges are counted consistently.
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
      serviceGraphMetrics:
        enabled: true
        loadBalancer:
          resolver: static  # <-- The key change from the default
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
