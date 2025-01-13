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

clusterMetrics:
  enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true
```
