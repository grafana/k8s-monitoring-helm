<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Istio Ambient Mode example

This example shows how to deploy within a cluster that has Istio enabled in [ambient mode](https://istio.io/latest/docs/ambient/overview/).
Unlike sidecar mode, ambient uses a per-node ztunnel instead of a per-pod Envoy sidecar, so the two workarounds required
by the sidecar-mode example are not needed:

* Alloy clustering's headless Service can keep its default `http` port name — ztunnel operates at L4 and does not apply
  the HTTP inspection that breaks the headless Service in sidecar mode.
* The Alloy Receiver does not need the `TPROXY` interception mode annotation because there is no sidecar intercepting
  inbound traffic; the `otelcol.processor.k8sattributes` component sees the originating pod's IP directly.

Because ambient mode has no per-pod sidecar, the Istio `sidecarMetrics` are not applicable — only `istiodMetrics` are
scraped by this example. If you later add a [waypoint proxy](https://istio.io/latest/docs/ambient/usage/waypoint/),
you can scrape its metrics via pod annotations the same way the sidecar example does.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: istio-ambient-test

destinations:
  localPrometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
    auth:
      type: basic
      username: promuser
      password: prometheuspassword
  localLoki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword
  localTempo:
    type: otlp
    url: tempo.tempo.svc:4317
    tls:
      insecure: true
      insecureSkipVerify: true
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

clusterMetrics:
  enabled: true
  collector: alloy-metrics

hostMetrics:
  enabled: true
  collector: alloy-metrics
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true

clusterEvents:
  enabled: true
  collector: alloy-singleton

podLogsViaLoki:
  enabled: true
  collector: alloy-logs

integrations:
  collector: alloy-metrics
  istio:
    instances:
      - name: istio
        # Ambient mode has no per-pod sidecars; only istiod metrics are scraped.
        sidecarMetrics:
          enabled: false
        istiodMetrics:
          enabled: true

applicationObservability:
  enabled: true
  collector: alloy-receiver
  receivers:
    otlp:
      grpc:
        enabled: true
      http:
        enabled: true
  connectors:
    grafanaCloudMetrics:
      enabled: true
  logs:
    enabled: false

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
    controller:
      replicas: 2  # To test that clustering is working
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
  alloy-singleton:
    presets: [singleton]
  alloy-receiver: {}

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
