<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# feature-pod-logs

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)
Kubernetes Observability feature for gathering Pod logs.

The Pod Logs feature enables the collection of logs from Kubernetes Pods on the cluster.

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `deployAsConfigMap` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
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
| labelsToKeep | list | `["app_kubernetes_io_name","container","instance","job","level","namespace","pod","service_name","service_namespace","deployment_environment","deployment_environment_name"]` | The list of labels to keep on the logs, all other pipeline labels will be dropped. |
| staticLabels | object | `{}` | Log labels to set with static values. |
| staticLabelsFrom | object | `{}` | Log labels to set with static values, not quoted so it can reference config components. |

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |

### Kubernetes API Gathering: Discovery

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubernetesApiGathering.excludeNamespaces | list | `[]` | Do not capture logs from any pods in these namespaces. |
| kubernetesApiGathering.extraDiscoveryRules | string | `""` | Rules to filter pods for log gathering. |
| kubernetesApiGathering.fieldSelectors | list | `[]` | Discover Pods based on field selectors. |
| kubernetesApiGathering.labelSelectors | object | `{}` | Discover Pods based on label selectors. |
| kubernetesApiGathering.namespaces | list | `[]` | Only capture logs from pods in these namespaces (`[]` means all namespaces). |
| kubernetesApiGathering.nodeFieldSelectors | list | `[]` | Discover Pods based on Node field selectors. |
| kubernetesApiGathering.nodeLabelSelectors | object | `{}` | Discover Pods based on Node label selectors. |
| kubernetesApiGathering.nodes | list | `[]` | Do not capture logs from any pods in these namespaces. |
| volumeGathering.nodeFieldSelectors | list | `[]` | Discover Pods based on Node field selectors. |
| volumeGathering.nodeLabelSelectors | object | `{}` | Discover Pods based on Node label selectors. |

### Processing settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| structuredMetadata | object | `{}` | The structured metadata mappings to set. To not set any structured metadata, set this to an empty object (e.g. `{}`) Format: `<key>: <extracted_key>`. Example: structuredMetadata:   component: component   kind: kind   name: name |

### Volume Gathering: Discovery

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| volumeGathering.excludeNamespaces | list | `[]` | Do not capture logs from any pods in these namespaces. |
| volumeGathering.extraDiscoveryRules | string | `""` | Rules to filter pods for log gathering. |
| volumeGathering.fieldSelectors | list | `[]` | Discover Pods based on field selectors. |
| volumeGathering.labelSelectors | object | `{}` | Discover Pods based on label selectors. |
| volumeGathering.namespaces | list | `[]` | Only capture logs from pods in these namespaces (`[]` means all namespaces). |
| volumeGathering.podLogsPath | string | `"/var/log/pods"` | Path on the Kubernetes nodes where the Pod logs are stored. |

### Volume Gathering: Gathering

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| volumeGathering.onlyGatherNewLogLines | bool | `false` | Only gather new log lines since this was deployed. Do not gather historical log lines. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubernetesApiGathering.enabled | bool | `false` | Only capture logs from pods in these namespaces (`[]` means all namespaces). |
| lokiReceiver.enabled | bool | `false` | Enable receiving logs using the Loki protocol. |
| lokiReceiver.openShiftClusterLogForwarder.enabled | bool | `false` |  |
| lokiReceiver.openShiftClusterLogForwarder.namespaces | list | `[]` |  |
| lokiReceiver.port | int | `3100` | The port to listen on for logs. |
| volumeGathering.enabled | bool | `true` |  |
