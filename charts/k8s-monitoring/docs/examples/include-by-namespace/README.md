<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Include By Namespace

This example demonstrates how to include telemetry data from a list of namespaces, dropping data from all other
namespaces.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: include-by-namespace-test

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
    protocol: http
    url: http://tempo.tempo.svc:443/otlp
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}
  pyroscope:
    type: pyroscope
    url: http://pyroscope.pyroscope.svc:4040

annotationAutodiscovery:
  enabled: true
  collector: alloy-metrics
  namespaces: [alpha, bravo, delta]

applicationObservability:
  enabled: true
  collector: alloy-receiver
  receivers:
    otlp:
      grpc:
        enabled: true
  metrics:
    filters:
      metric:
        - not(IsMatch(resource.attributes["k8s.namespace.name"], "^alpha|bravo|delta$"))
      logs:
        - not(IsMatch(resource.attributes["k8s.namespace.name"], "^alpha|bravo|delta$"))
      traces:
        - not(IsMatch(resource.attributes["k8s.namespace.name"], "^alpha|bravo|delta$"))

autoInstrumentation:
  enabled: true
  collector: alloy-metrics
  beyla:
    config:
      data:
        discovery:
          services:
            - k8s_namespace: alpha
            - k8s_namespace: bravo
            - k8s_namespace: delta

clusterEvents:
  enabled: true
  collector: alloy-singleton
  namespaces: [alpha, bravo, delta]

clusterMetrics:
  enabled: true
  collector: alloy-metrics
  cadvisor:
    metricsTuning:
      includeNamespaces: [alpha, bravo, delta]

hostMetrics:
  enabled: true
  collector: alloy-metrics
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true

podLogs:
  enabled: true
  collector: alloy-logs
  namespaces: [alpha, bravo, delta]

profiling:
  enabled: true
  collector: alloy-profiles
  ebpf:
    namespaces: [alpha, bravo, delta]
  java:
    namespaces: [alpha, bravo, delta]
  pprof:
    namespaces: [alpha, bravo, delta]

prometheusOperatorObjects:
  enabled: true
  collector: alloy-metrics
  probes:
    namespaces: [alpha, bravo, delta]
  podMonitors:
    namespaces: [alpha, bravo, delta]
  serviceMonitors:
    namespaces: [alpha, bravo, delta]

collectors:
  alloy-metrics: {}

  alloy-singleton: {}

  alloy-logs: {}

  alloy-receiver:
    alloy:
      extraPorts:
        - name: otlp-grpc
          port: 4317
          targetPort: 4317
          protocol: TCP

  alloy-profiles: {}

telemetryServices:
  kube-state-metrics:
    deploy: true
    namespaces: [alpha, bravo, delta]
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
