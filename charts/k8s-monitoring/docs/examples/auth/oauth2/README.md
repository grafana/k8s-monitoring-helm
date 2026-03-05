<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# OAuth2 Authentication

This example demonstrates how to use OAuth2 for authentication.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: oauth2-auth-example

destinations:
  - name: otel-endpoint
    type: otlp
    url: "grpc.my.otel.endpoint:443"
    auth:
      type: oauth2
      oauth2:
        tokenURL: "https://my.idp/application/o/token/"
        clientId: "my-client-id"
        clientSecretFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
        endpointParams:
          grant_type: ["client_credentials"]
          client_assertion_type: ["urn:ietf:params:oauth:client-assertion-type:jwt-bearer"]
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: true}

clusterMetrics:
  enabled: true

clusterEvents:
  enabled: true

podLogs:
  enabled: true

nodeLogs:
  enabled: true

prometheusOperatorObjects:
  enabled: true

annotationAutodiscovery:
  enabled: true

alloy-logs:
  enabled: true
alloy-metrics:
  enabled: true
alloy-singleton:
  enabled: true
```
<!-- textlint-enable terminology -->
