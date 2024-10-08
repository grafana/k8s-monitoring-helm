<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Bearer Token Authentication

This example demonstrates how to use a bearer token for authentication. The Prometheus destination defines the bearer
token inside the values file. The Loki destination gets a bearer token from an environment variable defined on the
`alloy-logs` collector. And the OTLP destination gets a bearer token from a pre-existing Kubernetes secret.

## Values

```yaml
---
cluster:
  name: bearer-token-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
    auth:
      type: bearerToken
      bearerToken: sample-bearer-token

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    auth:
      type: bearerToken
      bearerTokenFrom: env("LOKI_BEARER_TOKEN")

  - name: tempo
    type: otlp
    url: http://tempo.tempo.svc:4317
    auth:
      type: bearerToken
      bearerTokenKey: tempoBearerToken
    secret:
      create: false
      name: my-tempo-secret
      namespace: tempo

applicationObservability:
  enabled: true
  receivers:
    grpc:
      enabled: true

prometheusOperatorObjects:
  enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true
  alloy:
    extraEnv:
      - name: LOKI_BEARER_TOKEN
        value: sample-bearer-token

alloy-receiver:
  enabled: true
  alloy:
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP
```
