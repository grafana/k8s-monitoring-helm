<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Kubernetes Enrichment processor: Labels and Annotations

This example uses the `kubernetesEnrichment` data processor to copy Kubernetes namespace and pod metadata onto
telemetry data. Each entry maps `<telemetry label>: <Kubernetes label or annotation name>`. A single `k8s-metadata`
processor copies:

| Source            | Metadata                       | Resulting label / attribute             |
| ----------------- | ------------------------------ | --------------------------------------- |
| Namespace         | `team` label                   | `team`                                  |
| Namespace         | `cost-center` annotation       | `cost_center` (OTLP: `cost-center`)     |
| Pod               | `color` label                  | `color`                                 |
| Pod               | `example.com/owner` annotation | `owner`                                 |

Four features opt in to it via `dataProcessors: [k8s-metadata]`:

| Telemetry | Feature                    | Ecosystem    | How metadata is attached                    |
| --------- | -------------------------- | ------------ | ------------------------------------------- |
| Metrics   | `clusterMetrics`           | `prometheus` | `prometheus.enrich` (experimental)          |
| Logs      | `podLogsViaLoki`           | `loki`       | `loki.enrich` (experimental)                |
| Traces    | `applicationObservability` | `otlp`       | `otelcol.processor.k8sattributes`           |
| Profiles  | `profilesReceiver`         | `pyroscope`  | `pyroscope.enrich` (experimental)           |

Metrics, logs, and profiles are matched to their source namespace via their `namespace` label, and to their source pod
via their `namespace` and `pod` labels. OTLP traces are matched via Kubernetes resource attributes or the sender's
connection address. Because the label-based enrichment components are experimental, the collector running them sets
`alloy.stabilityLevel: experimental`.

All four features run on a single `alloy` collector, which shows the processor's shared pod discovery: the
`prometheus.enrich`, `loki.enrich`, and `pyroscope.enrich` stages all read targets from one
`discovery.kubernetes`/`discovery.relabel` pair, so the Kubernetes API is only watched once per collector.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: kubernetes-enrichment

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
  # Copies Kubernetes metadata onto telemetry: the `team` namespace label, the
  # `cost-center` namespace annotation, the `color` pod label, and the
  # `example.com/owner` pod annotation. Each entry maps
  # `<telemetry label>: <Kubernetes label or annotation name>`, so metrics, logs, and
  # profiles gain `team`, `cost_center`, `color`, and `owner` labels (label-based
  # ecosystems sanitize the telemetry label name); OTLP traces gain resource attributes
  # under the telemetry label names.
  k8s-metadata:
    type: kubernetesEnrichment
    namespaceLabels:
      team: team
    namespaceAnnotations:
      cost-center: cost-center
    podLabels:
      color: color
    podAnnotations:
      owner: example.com/owner

# Metrics
clusterMetrics:
  enabled: true
  collector: alloy
  dataProcessors: [k8s-metadata]

# Logs
podLogsViaLoki:
  enabled: true
  collector: alloy
  dataProcessors: [k8s-metadata]
  # By default, this feature moves the `pod` label to structured metadata. Keeping it as a
  # stream label lets the kubernetesEnrichment processor match log entries to their source
  # pod, which is required for copying pod labels and annotations.
  structuredMetadata:
    pod: null

# Traces
applicationObservability:
  enabled: true
  collector: alloy
  dataProcessors: [k8s-metadata]
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
  collector: alloy
  dataProcessors: [k8s-metadata]

collectors:
  alloy:
    presets: [clustered, filesystem-log-reader, daemonset]
    alloy:
      stabilityLevel: experimental  # Required for prometheus.enrich, loki.enrich, pyroscope.enrich
      extraPorts:
        - name: profiles
          port: 4040
          targetPort: 4040
          protocol: TCP
        - name: otlp-grpc
          port: 4317
          targetPort: 4317
          protocol: TCP

telemetryServices:
  kube-state-metrics:
    deploy: true
```
<!-- textlint-enable terminology -->
