<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Pod Logs

The Pod Logs feature enables the collection of logs from Kubernetes Pods on the cluster.

## Usage

```yaml
podLogsViaOpenTelemetry:
  enabled: true
```

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `deployAsConfigMap` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

<!-- textlint-disable terminology -->
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-pod-logs-via-opentelemetry>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Log Processing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations | object | `{}` | Log attributes to set with values copied from the Kubernetes Pod annotations. Format: `<log_label>: <kubernetes_annotation>`. |
| labels | object | `{"app_kubernetes_io_name":"app.kubernetes.io/name"}` | Log attributes to set with values copied from the Kubernetes Pod labels. Format: `<log_label>: <kubernetes_label>`. |
| namespaceAnnotations | object | `{}` | Log attributes to set with values copied from the Kubernetes Namespace annotations. Format: `<log_label>: <kubernetes_namespace_annotation>`. |
| namespaceLabels | object | `{}` | Log attributes to set with values copied from the Kubernetes Namespace labels. Format: `<log_label>: <kubernetes_namespace_label>`. |
| nodeAnnotations | object | `{}` | Log attributes to set with values copied from the Kubernetes Node annotations. Format: `<log_label>: <kubernetes_node_annotation>`. |
| nodeLabels | object | `{}` | Log attributes to set with values copied from the Kubernetes Node labels. Format: `<log_label>: <kubernetes_node_label>`. |
| otelAnnotations | bool | `false` | Whether to automatically set the recommended OpenTelemetry [resource attributes](https://opentelemetry.io/docs/specs/semconv/non-normative/k8s-attributes/). |
| staticAttributes | object | `{}` | Log attributes to set with static values. |
| staticAttributesFrom | object | `{}` | Log attributes to set with static values, not quoted so it can reference config components. |

### Pod Discovery

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| excludeNamespaces | list | `[]` | Do not capture logs from any pods in these namespaces. |
| namespaces | list | `[]` | Only capture logs from pods in these namespaces (`[]` means all namespaces). |

### Volume Log Gathering

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| onlyGatherNewLogLines | bool | `false` | Only gather new log lines since this was deployed. Do not gather historical log lines. |
