<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Pod Logs

The Pod Logs feature enables the collection of logs from Kubernetes Pods on the cluster.

## Usage

```yaml
podLogs:
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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-pod-logs>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Log Processing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations | object | `{"job":"k8s.grafana.com/logs.job"}` | Log labels to set with values copied from the Kubernetes Pod annotations. Format: `<log_label>: <kubernetes_annotation>`. |
| extraLogProcessingStages | string | `""` | Stage blocks to be added to the loki.process component for pod logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| labels | object | `{"app_kubernetes_io_name":"app.kubernetes.io/name"}` | Log labels to set with values copied from the Kubernetes Pod labels. Format: `<log_label>: <kubernetes_label>`. |
| labelsToKeep | list | `["app.kubernetes.io/name","container","instance","job","level","namespace","service.name","service.namespace","deployment.environment","deployment.environment.name","k8s.namespace.name","k8s.deployment.name","k8s.statefulset.name","k8s.daemonset.name","k8s.cronjob.name","k8s.job.name","k8s.node.name"]` | The list of labels to keep on the logs, all other pipeline labels will be dropped. |
| namespaceAnnotations | object | `{}` | Log labels to set with values copied from the Kubernetes Namespace annotations. Only used for "filelog" gather method. Format: `<log_label>: <kubernetes_namespace_annotation>`. |
| namespaceLabels | object | `{}` | Log labels to set with values copied from the Kubernetes Namespace labels. Only used for "filelog" gather method. Format: `<log_label>: <kubernetes_namespace_label>`. |
| nodeAnnotations | object | `{}` | Log labels to set with values copied from the Kubernetes Node annotations. Only used for "filelog" gather method. Format: `<log_label>: <kubernetes_node_annotation>`. |
| nodeLabels | object | `{}` | Log labels to set with values copied from the Kubernetes Node labels. Only used for "filelog" gather method. Format: `<log_label>: <kubernetes_node_label>`. |
| staticLabels | object | `{}` | Log labels to set with static values. |
| staticLabelsFrom | object | `{}` | Log labels to set with static values, not quoted so it can reference config components. |

### Pod Discovery

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| excludeNamespaces | list | `[]` | Do not capture logs from any pods in these namespaces. |
| extraDiscoveryRules | string | `""` | Rules to filter pods for log gathering. Only used for "volumes" or "kubernetesApi" gather methods. |
| gatherMethod | string | `"volumes"` | The method to gather pod logs. Options are "volumes", "filelog" (experimental), "kubernetesApi", "OpenShiftClusterLogForwarder" (experimental). DEPRECATION WARNING: The "kubernetesApi" gather method is deprecated and will be removed in a future release. Please use the podLogsViaKubernetesApi feature instead. |
| labelSelectors | object | `{}` | Filter the list of discovered pods and services by labels. Only for the "volumes" gather method. Example: `labelSelectors: { 'app': 'myapp' }` will only discover pods with the label `app=myapp`. Example: `labelSelectors: { 'app': ['myapp', 'myotherapp'] }` will only discover pods with the label `app=myapp` or `app=myotherapp`. |
| namespaces | list | `[]` | Only capture logs from pods in these namespaces (`[]` means all namespaces). |

### File Log Gathering

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| filelogGatherSettings.onlyGatherNewLogLines | bool | `false` | Only gather new log lines since this was deployed. Do not gather historical log lines. |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |

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

### Volume Log Gathering

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| volumeGatherSettings.onlyGatherNewLogLines | bool | `false` | Only gather new log lines since this was deployed. Do not gather historical log lines. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nodeSelectors | object | `{}` | Filter the list of discovered nodes by labels. Only for the "volumes" gather method. Example: `nodeSelectors: { 'kubernetes.io/os': 'linux' }` |
