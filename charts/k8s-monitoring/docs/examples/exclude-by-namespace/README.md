<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Exclude By Namespace

This example demonstrates how to exclude telemetry data from a list of namespaces, allowing data from all other
namespaces.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: exclude-by-namespace-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push
  - name: tempo
    type: otlp
    protocol: http
    url: http://tempo.tempo.svc:443/otlp
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}
  - name: pyroscope
    type: pyroscope
    url: http://pyroscope.pyroscope.svc:4040

annotationAutodiscovery:
  enabled: true
  excludeNamespaces: [kube-system, kube-public, confidential]

applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true
  metrics:
    filters:
      metric:
        - IsMatch(resource.attributes["k8s.namespace.name"], "^kube-system|kube-public|confidential$")
      logs:
        - IsMatch(resource.attributes["k8s.namespace.name"], "^kube-system|kube-public|confidential$")
      traces:
        - IsMatch(resource.attributes["k8s.namespace.name"], "^kube-system|kube-public|confidential$")
  processors:
    k8sattributes:
      filters:
        byField:
          - key: metadata.namespace
            op: not-equals
            value: kube-system
          - key: metadata.namespace
            op: not-equals
            value: kube-public
          - key: metadata.namespace
            op: not-equals
            value: confidential

autoInstrumentation:
  enabled: true
  beyla:
    config:
      data:
        discovery:
          services:
            - k8s_namespace: .
          exclude_services:
            - k8s_namespace: kube-system
            - k8s_namespace: kube-public
            - k8s_namespace: confidential

clusterEvents:
  enabled: true
  excludeNamespaces: [kube-system, kube-public, confidential]

clusterMetrics:
  enabled: true
  cadvisor:
    metricsTuning:
      excludeNamespaces: [kube-system, kube-public, confidential]
  kube-state-metrics:
    namespacesDenylist: [kube-system, kube-public, confidential]

podLogs:
  enabled: true
  excludeNamespaces: [kube-system, kube-public, confidential]

profiling:
  enabled: true
  ebpf:
    excludeNamespaces: [kube-system, kube-public, confidential]
  java:
    excludeNamespaces: [kube-system, kube-public, confidential]
  pprof:
    excludeNamespaces: [kube-system, kube-public, confidential]

prometheusOperatorObjects:
  enabled: true
  probes:
    excludeNamespaces: [kube-system, kube-public, confidential]
  podMonitors:
    excludeNamespaces: [kube-system, kube-public, confidential]
  serviceMonitors:
    excludeNamespaces: [kube-system, kube-public, confidential]

alloy-metrics:
  enabled: true

alloy-singleton:
  enabled: true

alloy-logs:
  enabled: true

alloy-receiver:
  enabled: true
  alloy:
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP

alloy-profiles:
  enabled: true
```
<!-- textlint-enable terminology -->
