<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Authentication with the Secrets Store CSI Driver

This example demonstrates how to use the [Kubernetes Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
to pull credentials directly from an external secrets manager, such as HashiCorp Vault, AWS Secrets Manager, Azure Key
Vault, or GCP Secret Manager, and mount them as files on the Alloy Pods, rather than storing them as Kubernetes
Secrets.

The CSI driver mounts the secrets as files through a `SecretProviderClass`. Alloy's `local.file` component then reads
those files and exposes their content as config values, which are referenced with `urlFrom`, `usernameFrom`, and
`passwordFrom`.

The Secrets Store CSI Driver and its provider plugin for your secrets manager must already be installed on the
cluster, and the `SecretProviderClass` is specific to your secrets manager, so neither is created by this chart. The
`SecretProviderClass` below is a representative example; check your provider's documentation for the exact
`parameters` to use.

## SecretProviderClass

Given this `SecretProviderClass` already exists on the cluster, adjust `provider` and `parameters` for your secrets
manager:

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: grafana-cloud-secrets
  namespace: monitoring
spec:
  provider: vault
  parameters:
    roleName: "grafana-cloud"
    objects: |
      - objectName: "loki-url"
        secretPath: "secret/data/grafana-cloud"
        secretKey: "loki-url"
      - objectName: "loki-username"
        secretPath: "secret/data/grafana-cloud"
        secretKey: "loki-username"
      - objectName: "prometheus-url"
        secretPath: "secret/data/grafana-cloud"
        secretKey: "prometheus-url"
      - objectName: "prometheus-username"
        secretPath: "secret/data/grafana-cloud"
        secretKey: "prometheus-username"
      - objectName: "password"
        secretPath: "secret/data/grafana-cloud"
        secretKey: "api-key"
```

`collectorCommon.alloy` applies the volume mount, the CSI volume, and the `local.file` components to every collector,
so each collector mounts the same `SecretProviderClass` and reads the same files without repeating the configuration
per collector.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: csi-secrets-store-example-cluster

destinations:
  prometheus:
    type: prometheus
    urlFrom: local.file.prometheus_url.content
    auth:
      type: basic
      usernameFrom: local.file.prometheus_username.content
      passwordFrom: local.file.password.content

  loki:
    type: loki
    urlFrom: local.file.loki_url.content
    auth:
      type: basic
      usernameFrom: local.file.loki_username.content
      passwordFrom: local.file.password.content

clusterMetrics:
  enabled: true
  collector: alloy-metrics

podLogsViaLoki:
  enabled: true
  collector: alloy-logs

collectorCommon:
  alloy:
    alloy:
      mounts:
        extra:
          - name: secrets-store-inline
            mountPath: "/var/run/secrets/secrets-store-inline"
            readOnly: true
    controller:
      volumes:
        extra:
          - name: secrets-store-inline
            csi:
              driver: secrets-store.csi.k8s.io
              readOnly: true
              volumeAttributes:
                secretProviderClass: grafana-cloud-secrets
    extraConfig: |
      local.file "loki_url" {
        filename = "/var/run/secrets/secrets-store-inline/loki-url"
      }
      local.file "loki_username" {
        filename = "/var/run/secrets/secrets-store-inline/loki-username"
      }
      local.file "prometheus_url" {
        filename = "/var/run/secrets/secrets-store-inline/prometheus-url"
      }
      local.file "prometheus_username" {
        filename = "/var/run/secrets/secrets-store-inline/prometheus-username"
      }
      local.file "password" {
        filename  = "/var/run/secrets/secrets-store-inline/password"
        is_secret = true
      }

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]

telemetryServices:
  kube-state-metrics:
    deploy: true
```
<!-- textlint-enable terminology -->
