<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Authentication with Pre-existing Secrets

This example demonstrates how to use pre-existing secrets to authenticate to external services. This allows for
credentials to be stored in different secret stores, as long as it resolves to a Kubernetes Secret.

<!--alex disable hostesses-hosts-->
This also shows how to use secrets to store the destination hosts, rather than embedding directly in the configuration.
This uses the `urlFrom` field, which allows for inserting raw Alloy configuration. In this case, referencing the secret
component and appending the paths if necessary.
<!--alex enable hostesses-hosts-->

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
  prom-host: http://prometheus.prometheus.svc:9090
  prom-username: "12345"
  loki-host: http://loki.loki.svc:3100
  loki-username: "67890"
  fleet-management-host: "112233"
  fleet-management-user: "112233"
  access-token: "It's a secret to everyone"
---
apiVersion: v1
kind: Secret
metadata:
  name: my-tempo-secret
  namespace: tempo
type: Opaque
stringData:
  tempohost: http://tempo.tempo.svc:4317
  tempoBearerToken: "It's a secret to everyone"
```

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: external-secrets-example-cluster

destinations:
  - name: metrics-service
    type: prometheus
    urlFrom: convert.nonsensitive(remote.kubernetes.secret.metrics_service.data["prom-host"]) + "/api/v1/write"
    auth:
      type: basic
      usernameKey: prom-username
      passwordKey: access-token
    secret:
      create: false
      name: my-monitoring-secret
      namespace: monitoring

  - name: logs-service
    type: loki
    urlFrom: convert.nonsensitive(remote.kubernetes.secret.logs_service.data["loki-host"]) + "/loki/api/v1/push"
    auth:
      type: basic
      usernameKey: loki-username
      passwordKey: access-token
    secret:
      create: false
      name: my-monitoring-secret
      namespace: monitoring

  - name: traces-service
    type: otlp
    urlFrom: convert.nonsensitive(remote.kubernetes.secret.traces_service.data["tempo-host"])
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
  remoteConfig:
    enabled: true
    urlFrom: convert.nonsensitive(remote.kubernetes.secret.alloy_metrics_remote_cfg.data["fleet-management-host"])
    auth:
      type: basic
      usernameKey: fleet-management-user
      passwordKey: access-token
    secret:
      create: false
      name: my-monitoring-secret
  alloy:
    extraEnv:
      - name: GCLOUD_RW_API_KEY
        valueFrom:
          secretKeyRef:
            name: my-monitoring-secret
            key: access-token
      - name: CLUSTER_NAME
        value: external-secrets-example-cluster
      - name: NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace
      - name: NODE_NAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
      - name: GCLOUD_FM_COLLECTOR_ID
        value: k8smon-$(CLUSTER_NAME)-$(NAMESPACE)-alloy-logs-$(NODE_NAME)

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
