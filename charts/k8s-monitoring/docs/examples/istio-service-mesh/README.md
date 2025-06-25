<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Istio Service Mesh example

This example shows how to deploy within a cluster when Istio Service Mesh is enabled and has deployed the Istio
sidecar to the Alloy pods.

## Alloy Clustering

A change must be made to any Alloy instance that is using Alloy clustering because the Alloy cluster's headless Service
port name [will not work](https://istio.io/latest/docs/ops/common-problems/network-issues/#503-error-while-accessing-headless-services)
if it keeps its default port name of `http`.

## Alloy Receiver

Another change must be made for the Alloy receiver which accepts data from applications. The Application Observability
feature utilizes a [otelcol.processor.k8sattributes](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.k8sattributes/)
component which enriches the telemetry data with Kubernetes metadata. This component uses the IP address of the
application pod to look up the metadata. Setting the Istio sidecar's [interception mode](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig-InboundInterceptionMode)
to `TPROXY` will preserve originating pod's IP and port, allowing the component to work as expected.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: istio-service-mesh-example

destinations:
  - name: localPrometheus
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
  - name: localTempo
    type: otlp
    url: tempo.tempo.svc:4317
    tls:
      insecure: true
      insecureSkipVerify: true
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

annotationAutodiscovery:
  enabled: true
  annotations:
    scrape: prometheus.io/scrape
    metricsPath: prometheus.io/path
    metricsPortNumber: prometheus.io/port

clusterMetrics:
  enabled: true

applicationObservability:
  enabled: true
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

alloy-metrics:
  enabled: true
  alloy:
    clustering:
      portName: tcp
  controller:
    replicas: 2

alloy-receiver:
  enabled: true
  liveDebugging:
    enabled: true
  controller:
    # Using TPROXY preserves both the source and destination IP addresses and ports, which allows
    # the k8sattributes processor to look up the pod by IP and enrich the rest of the attributes
    podAnnotations:
      sidecar.istio.io/interceptionMode: TPROXY
```
<!-- textlint-enable terminology -->
