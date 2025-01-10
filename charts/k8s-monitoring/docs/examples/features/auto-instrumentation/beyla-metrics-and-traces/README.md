<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Auto-Instrumentation with Beyla for Metrics and Traces

This example demonstrates how to enable the auto-instrumentation feature, which deploys Grafana Beyla to automatically
instrument your application for metrics collection. It also coordinates with the Application Observability feature to
generate traces for your application.

## Values

```yaml
---
cluster:
  name: annotation-autodiscovery-with-traces-cluster

destinations:
  - name: otlp-gateway
    type: otlp
    url: http://otlp-gateway.example.com
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: true}

applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true

autoInstrumentation:
  enabled: true
  beyla:
    config:
      data:
        attributes:
          kubernetes:
            enable: true
          select:
            beyla_network_flow_bytes:
              include:
                - direction
                - k8s.cluster.name
                - k8s.dst.name
                - k8s.dst.namespace
                - k8s.dst.owner.name
                - k8s.dst.owner.type
                - k8s.src.name
                - k8s.src.namespace
                - k8s.src.owner.name
                - k8s.src.owner.type
        discovery:
          exclude_otel_instrumented_services: false
          services:
            - k8s_pod_labels:
                instrument: beyla
        log_level: debug
        network:
          enable: true
        prometheus_export:
          path: /metrics
          features:
            - application
            - application_process
            - application_service_graph
            - application_span
            - network
        internal_metrics:
          prometheus:
            path: /internal/metrics
            routes:
        patterns:
          - /account
          - /api/products/{productId}
          - /cart
          - /fastcache
          - /health
          - /login
          - /payment
        ignored_patterns:
          - /debug/*
          - /metrics
        unmatched: heuristic
  preset: application

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
