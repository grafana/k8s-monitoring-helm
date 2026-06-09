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

## Service name and namespace detection

This feature sets the `service.name` and `service.namespace` resource attributes on collected logs. The default
detection chain for `service.name` is, in order: the `resource.opentelemetry.io/service.name` pod annotation, the
workload owner name (Deployment, StatefulSet, etc.), the pod name, and the container name.

Set `alignServiceNameWithOTelOperator: true` to opt in to the
[OpenTelemetry Operator service name conventions](https://opentelemetry.io/docs/specs/semconv/non-normative/k8s-attributes/)
instead. These are also what Grafana Beyla uses for application metrics, so enabling this flag makes `service.name`
consistent across metrics, logs, traces, and profiles from the same workload. The chain becomes:

1.  The `resource.opentelemetry.io/service.name` pod annotation
2.  The `app.kubernetes.io/instance` pod label
3.  The `app.kubernetes.io/name` pod label
4.  The name of the workload that owns the pod (Deployment, StatefulSet, DaemonSet, CronJob, Job, ...)
5.  The pod name
6.  The container name

When the flag is enabled, the `service.version` resource attribute is also populated from the
`app.kubernetes.io/version` pod label.

In either mode, `service.namespace` is set to the first value found from: the
`resource.opentelemetry.io/service.namespace` pod annotation, then the pod namespace.

To pin a specific service name for a workload, set the `resource.opentelemetry.io/service.name` annotation on the
pod. It takes the highest precedence in every mode.

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
| alignServiceNameWithOTelOperator | bool | `false` | Align the `service.name` resource attribute with the [OpenTelemetry Operator service name conventions](https://opentelemetry.io/docs/specs/semconv/non-normative/k8s-attributes/) (which is what Grafana Beyla uses). When enabled, the detection chain becomes: pod annotation `resource.opentelemetry.io/service.name` → pod label `app.kubernetes.io/instance` → pod label `app.kubernetes.io/name` → owner workload name (Deployment, StatefulSet, etc.) → pod name → container name. The `service.version` resource attribute is similarly detected from the `app.kubernetes.io/version` pod label. |
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
| annotationSelector | string | `"logs.grafana.com/pods.enabled"` | Pod annotation to use for controlling log discovery. If a pod has this annotation, it will either enable or disable gathering of logs, depending on the value of the discoveryMethod. |
| discoveryMethod | string | `"all"` | Controls the behavior of discovering pods for logs. Possible values: `all`, `annotation`. When set to "all", every pod (filtered by the namespace and label selectors) will have their logs gathered. When set to "annotation", only pods with the annotation selector set to something other than "false", "no" or "skip" will have their logs gathered. |
| excludeNamespaces | list | `[]` | Do not capture logs from any pods in these namespaces. |
| namespaces | list | `[]` | Only capture logs from pods in these namespaces (`[]` means all namespaces). |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.namespaceOverride | string | `""` | Override the namespace for namespaced resources created by this chart. |

### Volume Log Gathering

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| onlyGatherNewLogLines | bool | `true` | Only gather new log lines since this was deployed. Do not gather historical log lines. |
