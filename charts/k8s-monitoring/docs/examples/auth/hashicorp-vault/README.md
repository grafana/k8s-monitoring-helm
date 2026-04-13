<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Authentication with Hashicorp Vault

This example demonstrates how to use [Hashicorp Vault](https://www.vaultproject.io/) to manage secrets for the
Kubernetes Monitoring Helm chart.

The chart supports referencing pre-existing Kubernetes Secrets via the `secret.create: false` configuration. You can use
any Vault integration method to create those Kubernetes Secrets:

- [Vault Secrets Operator](https://developer.hashicorp.com/vault/docs/platform/k8s/vso) (recommended) — syncs Vault
  secrets directly into Kubernetes Secrets
- [Vault CSI Provider](https://developer.hashicorp.com/vault/docs/platform/k8s/csi) — uses the Secrets Store CSI
  Driver to mount secrets as volumes and optionally sync them to Kubernetes Secrets
- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector) — injects secrets into pod
  filesystems via sidecar

## Vault Setup

Store your monitoring credentials in Vault:

```shell
vault kv put secret/monitoring \
  username="12345" \
  password="my-secret-token" \
  loki-username="67890" \
  loki-password="my-secret-token"
```

Create a Vault policy that allows reading these secrets:

```shell
vault policy write monitoring-policy - <<EOF
path "secret/data/monitoring" {
  capabilities = ["read"]
}
EOF
```

## Option 1: Vault Secrets Operator

The Vault Secrets Operator creates and manages Kubernetes Secrets directly from Vault. Install the operator, then create
a `VaultStaticSecret` resource:

```yaml
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: monitoring-credentials
spec:
  type: kv-v2
  mount: secret
  path: monitoring
  refreshAfter: 60s
  destination:
    name: monitoring-credentials
    create: true
    type: Opaque
```

The operator will create a Kubernetes Secret named `monitoring-credentials` containing all the keys from the Vault
secret. The Helm chart references this secret using `secret.create: false` and `secret.name: monitoring-credentials`.

## Option 2: Vault CSI Provider

If using the Vault CSI Provider, create a `SecretProviderClass` and add CSI volume mounts to the collectors:

```yaml
---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-monitoring-secrets
spec:
  provider: vault
  parameters:
    roleName: monitoring
    vaultAddress: http://vault.vault.svc:8200
    objects: |
      - objectName: "username"
        secretPath: "secret/data/monitoring"
        secretKey: "username"
      - objectName: "password"
        secretPath: "secret/data/monitoring"
        secretKey: "password"
      - objectName: "loki-username"
        secretPath: "secret/data/monitoring"
        secretKey: "loki-username"
      - objectName: "loki-password"
        secretPath: "secret/data/monitoring"
        secretKey: "loki-password"
  secretObjects:
    - secretName: monitoring-credentials
      type: Opaque
      data:
        - objectName: username
          key: username
        - objectName: password
          key: password
        - objectName: loki-username
          key: loki-username
        - objectName: loki-password
          key: loki-password
```

Then add `extraVolumes` and `extraVolumeMounts` to the collectors in your values:

```yaml
collectors:
  alloy-metrics:
    alloy:
      extraVolumes:
        - name: vault-secrets
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: vault-monitoring-secrets
      extraVolumeMounts:
        - name: vault-secrets
          mountPath: /mnt/secrets-store
          readOnly: true
```

The CSI driver requires at least one pod to mount the volume in order to sync the secret. The `extraVolumes` and
`extraVolumeMounts` configuration triggers the sync.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: hashicorp-vault-example-cluster

destinations:
  metrics-service:
    type: prometheus
    url: http://nginx-auth-gateway.default.svc/metrics/basic/api/v1/write
    auth:
      type: basic
      usernameKey: username
      passwordKey: password
    secret:
      create: false
      name: monitoring-credentials
      namespace: default

  logs-service:
    type: loki
    url: http://nginx-auth-gateway.default.svc/logs/basic/loki/api/v1/push
    tenantId: 1
    auth:
      type: basic
      usernameKey: loki-username
      passwordKey: loki-password
    secret:
      create: false
      name: monitoring-credentials
      namespace: default

clusterMetrics:
  enabled: true
  collector: alloy-metrics
  kubelet:
    metricsTuning:
      includeMetrics: [kubernetes_build_info]
  kubeletResource:    {enabled: false}
  cadvisor:           {enabled: false}
  kube-state-metrics: {enabled: false, deploy: false}
  node-exporter:      {enabled: false, deploy: false}
  windows-exporter:   {enabled: false, deploy: false}

podLogsViaLoki:
  enabled: true
  collector: alloy-logs
  namespaces: ["default"]

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
```
<!-- textlint-enable terminology -->
