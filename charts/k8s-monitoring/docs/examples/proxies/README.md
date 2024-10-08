<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Proxies

This example shows how to use proxy URLs and TLS settings to modify how to send data to the external services.

For Alloy, the [prometheus.remote_write](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.remote_write/),
[loki.write](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.write/), and
[pyroscope.write](https://grafana.com/docs/alloy/latest/reference/components/pyroscope/pyroscope.write/) components all
support direct setting of a `proxyURL`. The [otelcol.exporter.otlp[http]](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.exporter.otlp/)
component does not, but uses the `HTTP_PROXY` and `NO_PROXY` environment variables to set a proxy.

## Values

```yaml
---
cluster:
  name: proxies-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
    proxyURL: https://myproxy.default.svc:8080
    tls:
      insecure_skip_verify: true

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    proxyURL: https://myproxy.default.svc:8080
    tls:
      insecure_skip_verify: true

  - name: tempo
    type: otlp
    url: http://tempo.tempo.svc:4317
    tls:
      insecure_skip_verify: true

  - name: pyroscope
    type: pyroscope
    url: http://pyroscope.pyroscope.svc:4040
    proxyURL: https://myproxy.default.svc:8080
    tls:
      insecure_skip_verify: true

clusterMetrics:
  enabled: true

clusterEvents:
  enabled: true

applicationObservability:
  enabled: true
  receivers:
    grpc:
      enabled: true

podLogs:
  enabled: true

profiling:
  enabled: true

alloy-metrics:
  enabled: true
alloy-singleton:
  enabled: true
alloy-logs:
  enabled: true
alloy-receiver:
  enabled: true
  alloy:
    extraEnv:
      - name: HTTP_PROXY
        value: https://myproxy.default.svc:8080
      - name: NO_PROXY
        value: kubernetes.default.svc
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP
alloy-profiles:
  enabled: true
```
