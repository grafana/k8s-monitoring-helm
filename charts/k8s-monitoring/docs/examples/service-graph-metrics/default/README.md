<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Service Graph Metrics

This example shows how to generate service graph metrics from traces using the k8s-monitoring Helm chart.

## What are Service Graph Metrics?

Service graph metrics describe the relationships between the services in your system. They are built by pairing the
client span and the server span of each request, producing metrics such as `traces_service_graph_request_total` and
`traces_service_graph_request_server_seconds` for every edge (caller → callee) in your architecture. Grafana uses these
metrics to draw the Service Graph and the node graph on the Tempo data source.

Rather than relying on Tempo's metrics generator, this example generates the metrics inside the collector, so they can
be written to any metrics destination.

## How it works

Enabling `serviceGraphMetrics` on an OTLP destination deploys a dedicated Alloy instance that runs
the [`otelcol.connector.servicegraph`](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.connector.servicegraph/)
component and writes the resulting metrics to the metrics destinations (Prometheus, in this example).

To build an edge, a grapher must see **both** the client span and the server span of a request. If those two spans
landed on different graphers, the edge would never be completed. To prevent that, the receiver forwards traces through
an `otelcol.exporter.loadbalancing` component, which consistently routes every span of a given trace ID to the same
grapher.

This matters most when the receiver is scaled out. In this example the receiver is a **DaemonSet**, so an application's
replicas may send their spans to different replicas of the receiver. No matter which receiver pod a span arrives on, the
load balancing exporter ensures the whole trace is reassembled on a single grapher:

```text
  workload replicas (many nodes)
        │  OTLP
        ▼
  alloy (DaemonSet: one pod per node)
        │  loadbalancing exporter — routes by trace ID
        ▼
  service graphers (StatefulSet: 3 replicas)
        │  traces_service_graph_* metrics
        ▼
  Prometheus
```

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
