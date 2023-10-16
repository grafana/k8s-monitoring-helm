# External Secrets

This example shows how to refer to externally created secrets.

```yaml
cluster:
  name: external-secrets-test

externalServices:
  prometheus:
    secret:
      create: false
      name: prometheus
      namespace: monitoring

  loki:
    hostKey: lokiHost
    basicAuth:
      usernameKey: lokiUser
      passwordKey: lokiPass

    secret:
      create: false
      name: shared-password
      namespace: prometheus

  tempo:
    hostKey: tempoHost
    basicAuth:
      usernameKey: tempoUser
      passwordKey: tempoPass

    secret:
      create: false
      name: shared-password
      namespace: monitoring

traces:
  enabled: true

grafana-agent:
  agent:
    extraPorts:
      - name: "otlp-grpc"
        port: 4317
        targetPort: 4317
        protocol: "TCP"
      - name: "otlp-http"
        port: 4318
        targetPort: 4318
        protocol: "TCP"
```
