<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# OTLP Endpoint Example

Some cloud services allow for sending all telemetry data to a single endpoint, which will then distribute the data to
the appropriate backend databases for storage. In this Helm chart, the
[OTLP Destination](https://grafana.com/docs/grafana-cloud/send-data/otlp/send-data-otlp/) makes this possible. This
means that you can define a single destination for all of your telemetry data.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: otlp-gateway-test

destinations:
  - name: otlp-gateway
    type: otlp
    url: https://otlp-gateway-my-region.grafana.net/otlp
    protocol: http
    auth:
      type: basic
      username: my-gateway-username
      password: my-gateway-password
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: true}
    processors:
      transform:
        traces:
          resource:
            - set(resource.attributes["quoted"], "quted")
          resourceFrom:
            - string.format(`set(attributes["from_env"], %q)`, coalesce(sys.env("MY_ENV"), "undefined"))

    sendingQueue:
      enabled: true
      blockOnOverflow: true
      storage: otelcol.storage.file.otlp_gateway_queue_storage.handler
      batch:
        enabled: true
        flushTimeout: 1s
        sizer: items
        minSize: 100
        maxSize: 1000

clusterMetrics:
  enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true
  extraConfig: |
    otelcol.storage.file "otlp_gateway_queue_storage" {
      create_directory = true
      directory = "/var/lib/otlp_gateway_queue_storage"
    }

alloy-logs:
  enabled: true
  extraConfig: |
    otelcol.storage.file "otlp_gateway_queue_storage" {
      create_directory = true
      directory = "/var/lib/otlp_gateway_queue_storage"
    }
```
<!-- textlint-enable terminology -->
