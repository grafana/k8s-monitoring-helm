<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Embedded Secrets Example

This example shows how setting the `secret.embed = true` flag will skip creating Kubernetes Secrets and will embed the
secret data directly into the destination configuration.

## Values

```yaml
---
cluster:
  name: embedded-secrets-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
    auth:
      type: sigv4
      sigv4:
        region: ap-southeast-2
        accessKey: my-access-key
        secretKey: my-secret-key
    secret:
      embed: true

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    auth:
      type: bearerToken
      bearerToken: my-bearer-token
    secret:
      embed: true

  - name: tempo
    type: otlp
    url: http://tempo.tempo.svc:4317
    auth:
      type: basic
      username: my-username
      password: my-password
    secret:
      embed: true

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

alloy-receiver:
  enabled: true
  alloy:
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP
```
