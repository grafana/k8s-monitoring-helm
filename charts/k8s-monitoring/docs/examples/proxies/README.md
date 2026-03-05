<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Proxies

This example shows how to use proxy URLs and TLS settings to modify how to send data to the external services.

## Directly setting proxies

Most destinations allow for proxy settings to be set directly on the destination configuration.

```yaml
- name: prometheus
  type: prometheus
  url: http://prometheus.example.com/api/v1/write
  proxyURL: https://myproxy.default.svc:8080
  noProxy: settings.example.com
  proxyConnectHeader:
    "MYPROXY-HEADER": ["my-proxy-header-value"]
```

The `prometheus`, `loki`, and `pyroscope` destinations support setting the `proxyURL`, `noProxy`, and
`proxyConnectHeader` options.

When using the `otlp` destination, the `proxyURL` setting is available if using the `http` protocol. However, if using
the `grpc` protocol, the `proxyURL` setting is not available. Instead, you can
use [environment variables](#using-environment-variables).

## Using environment variables

Another option which will work for all destination types is to use the `HTTP_PROXY`, `HTTPS_PROXY` and/or `NO_PROXY`
environment variables. For `prometheus`, `loki`, and `pyroscope` destinations, use the `proxy_from_environment` option
to indicate that the proxy settings should be read from the environment variables. When using this method, watch out
for issues connecting to the Kubernetes API service, or other internal services.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: proxies-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.example.com/api/v1/write
    proxyURL: https://myproxy.default.svc:8080
    noProxy: settings.example.com
    proxyConnectHeader:
      "MYPROXY-HEADER": ["my-proxy-header-value"]
    tls:
      insecure_skip_verify: true

  - name: loki
    type: loki
    url: http://loki.example.com/loki/api/v1/push
    proxyURL: https://myproxy.default.svc:8080
    tls:
      insecure_skip_verify: true

  - name: tempo
    type: otlp
    protocol: grpc
    url: http://tempo.example.com:4317
    tls:
      insecure_skip_verify: true
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

  - name: otlpgateway
    type: otlp
    protocol: http
    url: https://otlpgateway.example.com:4317
    proxyURL: https://myproxy.default.svc:8080
    tls:
      insecure_skip_verify: true
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: true}

  - name: pyroscope
    type: pyroscope
    url: http://pyroscope.example.com:4040
    proxyURL: https://myproxy.default.svc:8080
    tls:
      insecure_skip_verify: true

clusterMetrics:
  enabled: true
  opencost:
    enabled: true
    metricsSource: prometheus
    opencost:
      exporter:
        defaultClusterId: proxies-example-cluster
        extraEnv:
          HTTPS_PROXY: https://myproxy.default.svc:8080
          NO_PROXY: kubernetes.default.svc
      prometheus:
        external:
          url: http://prometheus.example.com/api/v1/query

clusterEvents:
  enabled: true

applicationObservability:
  enabled: true
  receivers:
    zipkin:
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
    # The following are required for the OTLP destination using the gRPC protocol.
    # They are also used for any destination that sets `proxy_from_environment=true`.
    extraEnv:
      - name: HTTPS_PROXY
        value: https://myproxy.default.svc:8080
      - name: NO_PROXY
        value: kubernetes.default.svc
alloy-profiles:
  enabled: true
```
<!-- textlint-enable terminology -->
