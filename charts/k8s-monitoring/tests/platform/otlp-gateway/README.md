<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# OTLP Gateway

This test sends all telemetry — metrics, logs, and traces — to a single Grafana Cloud
[OTLP gateway](https://grafana.com/docs/grafana-cloud/send-data/otlp/) destination over OTLP/HTTP, instead of using
separate Prometheus and Loki destinations.

When Cluster Events are delivered over OTLP, the Grafana Cloud Kubernetes Monitoring app expects certain resource
attributes to be present, so this test maps the required labels onto the events.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: otlp-gateway-test

destinations:
  otlp-gateway:
    type: otlp
    url: https://otlp-gateway-prod-us-east-0.grafana.net/otlp
    protocol: http
    auth:
      type: basic
      usernameKey: OTLP_GATEWAY_USER
      passwordKey: OTLP_GATEWAY_PASS
    secret:
      create: false
      name: grafana-cloud-credentials
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: true}

integrations:
  alloy:
    instances:
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: ["alloy"]

clusterMetrics:
  enabled: true

hostMetrics:
  enabled: true
  linuxHosts:
    enabled: true

clusterEvents:
  enabled: true
  clustering: true

  # These labels are required by the Grafana Cloud Kubernetes Monitoring system if these events are delivered via OTLP.
  labels:
    resources.k8s.object.kind: kind
    resources.k8s.object.name: name

podLogsViaLoki:
  enabled: true

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true

collectors:
  alloy:
    presets: [clustered, filesystem-log-reader, daemonset]
```
<!-- textlint-enable terminology -->
