<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Authentication with Pre-existing Secrets

This example demonstrates how to use pre-existing secrets to authenticate to external services. This allows for
credentials to be stored in different secret stores, as long as it resolves to a Kubernetes Secret.

## Secret

Given these secrets already exist on the cluster, they can be used to authenticate to the external services.

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: my-monitoring-secret
  namespace: monitoring
type: Opaque
stringData:
  prom-username: "12345"
  loki-username: "67890"
  access-token: "It's a secret to everyone"
---
apiVersion: v1
kind: Secret
metadata:
  name: my-tempo-secret
  namespace: tempo
type: Opaque
stringData:
  tempoBearerToken: "It's a secret to everyone"
```

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: external-secrets-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
    auth:
      type: basic
      usernameKey: prom-username
      passwordKey: access-token
    secret:
      create: false
      name: my-monitoring-secret
      namespace: monitoring

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    auth:
      type: basic
      usernameKey: loki-username
      passwordKey: access-token
    secret:
      create: false
      name: my-monitoring-secret
      namespace: monitoring

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
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

applicationObservability:
  enabled: true
  receivers:
    jaeger:
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
      - name: jaeger-grpc
        port: 14250
        targetPort: 14250
        protocol: TCP
```
<!-- textlint-enable terminology -->
