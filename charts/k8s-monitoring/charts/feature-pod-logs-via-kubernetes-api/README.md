<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Pod Logs via Kubernetes API

The Pod Logs via Kubernetes API feature enables the collection of logs from Kubernetes Pods on the cluster by streaming
them from the Kubernetes API Server. This method of log collection is an alternative to reading log files directly from
the filesystem, and provides flexibility in environments where direct file access may be restricted or not feasible.

## Usage

```yaml
podLogsViaKubernetesApi:
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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-pod-logs-via-kubernetes-api>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Log Processing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations | object | `{"job":"k8s.grafana.com/logs.job"}` | Log labels to set with values copied from the Kubernetes Pod annotations. Format: `<log_label>: <kubernetes_annotation>`. |
| extraLogProcessingStages | string | `""` | Stage blocks to be added to the loki.process component for pod logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| labels | object | `{"app_kubernetes_io_name":"app.kubernetes.io/name"}` | Log labels to set with values copied from the Kubernetes Pod labels. Format: `<log_label>: <kubernetes_label>`. |
| staticLabels | object | `{}` | Log labels to set with static values. |
| staticLabelsFrom | object | `{}` | Log labels to set with static values, not quoted so it can reference config components. |

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| excludeNamespaces | list | `[]` | Do not capture logs from any pods in these namespaces. |
| extraDiscoveryRules | string | `""` | Rules to filter pods for log gathering. Only used for "volumes" or "kubernetesApi" gather methods. |
| labelSelectors | object | `{}` | Filter the list of discovered pods by labels. Example: `labelSelectors: { 'app': 'myapp' }` will only discover pods and services with the label `app=myapp`. Example: `labelSelectors: { 'app': ['myapp', 'myotherapp'] }` will only discover pods and services with the label `app=myapp` or `app=myotherapp`. |
| namespaces | list | `[]` | Only capture logs from pods in these namespaces (`[]` means all namespaces). |

### Node Labels

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nodeLabels.availabilityZone | bool | `false` | Whether or not to add the availability\_zone label |
| nodeLabels.instanceType | bool | `false` | Whether or not to add the instance\_type label |
| nodeLabels.nodeArchitecture | bool | `false` | Whether or not to add the node architecture label |
| nodeLabels.nodeOS | bool | `false` | Whether or not to add the os label |
| nodeLabels.nodePool | bool | `false` | Whether or not to attach the nodepool label |
| nodeLabels.nodeRole | bool | `false` | Whether or not to add the node\_role label |
| nodeLabels.region | bool | `false` | Whether or not to add the region label |

### Secret Filtering

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secretFilter.allowlist | list | `[]` | List of regular expressions to allowlist matching secrets. |
| secretFilter.enabled | bool | `false` | Enable secret filtering. |
| secretFilter.includeGeneric | bool | `false` | Include the generic API key rule. |
| secretFilter.partialMask | int | `0` | Show the first N characters of the secret. |

### Processing settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| structuredMetadata | object | `{"k8s.pod.name":"k8s.pod.name","pod":"pod","service.instance.id":"service.instance.id"}` | The structured metadata mappings to set. Format: `<key>: <extracted_key>`. Example: structuredMetadata:   component: component   kind: kind   name: name |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nodeSelectors | object | `{}` | Filter the list of discovered nodes by labels. Example: `nodeSelectors: { 'kubernetes.io/os': 'linux' }` |
