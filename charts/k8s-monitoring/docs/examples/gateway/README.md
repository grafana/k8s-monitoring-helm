<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Gateway example

This example shows how to send data from one or more "leaf" clusters to a gateway cluster, which will then send to the
regular database destinations. This pattern is useful if only one cluster has external access, or if intermediate
checks are required to redact or filter sensitive information or metrics.

This example shows three deployments of the Helm chart, two capture their telemetry data normally, but their
destinations target the gateway cluster deployment. The gateway cluster deployment only utilizes the receiver features,
and will deliver telemetry data sent to it to the databases.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: gateway

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
    extraLabels:
      gateway: "check"
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword
    extraLabels:
      gateway: "check"
  tempo:
    type: otlp
    url: tempo.tempo.svc:4317
    overwriteClusterLabel: false
    tls:
      insecure: true
      insecureSkipVerify: true
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}
    extraResourceAttributes:
      gateway: "check"
  pyroscope:
    type: pyroscope
    url: http://pyroscope.pyroscope.svc:4040
    overwriteClusterLabel: false
    extraLabels:
      gateway: "check"

prometheusMetricsReceiver:
  enabled: true

lokiLogsReceiver:
  enabled: true

profilesReceiver:
  enabled: true

applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc: {enabled: true}
  metrics: {enabled: false}
  logs: {enabled: false}
  traces: {enabled: true}

collectors:
  alloyGateway:
    presets: [deployment]
    extraService:
      enabled: true
      fullname: gateway
```
<!-- textlint-enable terminology -->
