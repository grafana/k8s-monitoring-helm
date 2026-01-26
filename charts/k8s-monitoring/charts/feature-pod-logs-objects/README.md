<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: PodLogs Objects

This feature will gather Kubernetes Pod logs using Alloy PodLogs objects.

## Usage

podLogsObjects:
  enabled: true
  ... [values](#values)

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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-pod-logs-objects>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| excludeNamespaces | list | `[]` | Do not look for PodLogs objects in these namespaces. |
| includePodMetadataLabels | bool | `true` | Preserve discovered pod metadata labels for use by downstream components. Required for setting these standard labels: `namespace`, `node`, `pod`, `container`. |
| labelSelectors | object | `{}` | Filter the list of PodLogs objects by labels. Example: `labelSelectors: { 'app': 'myapp' }` will only discover pods and services with the label `app=myapp`. Example: `labelSelectors: { 'app': ['myapp', 'myotherapp'] }` will only discover pods and services with the label `app=myapp` or `app=myotherapp`. |
| namespaces | list | `[]` | Which namespaces to look for PodLogs objects (`[]` means all namespaces). |
| nodeFilter | bool | `false` | Only choose the pods on the same pod as the Alloy instance. Requires the Alloy instance to use DaemonSet and will Automatically set the environment variable NODE_NAME to the Alloy Pod's current cluster node. |

### Log Processing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraLogProcessingRules | string | `""` | Rule blocks to be added to the loki.relabel component for pod logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.relabel/#rule)) This value is templated so that you can refer to other values from this file. |
| extraLogProcessingStages | string | `""` | Stage blocks to be added to the loki.process component for pod logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| onlyGatherNewLogLines | bool | `false` | Only gather new log lines since this was deployed. Do not gather historical log lines. |
| staticLabels | object | `{}` | Log labels to set with static values. |
| staticLabelsFrom | object | `{}` | Log labels to set with static values, not quoted so it can reference config components. |

### Secret Filtering

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secretFilter.allowlist | list | `[]` | List of regular expressions to allowlist matching secrets. |
| secretFilter.enableEntropy | bool | `false` | Enable entropy-based filtering. |
| secretFilter.enabled | bool | `false` | Enable secret filtering. |
| secretFilter.gitleaksConfigPath | string | `""` | Path to the custom gitleaks.toml file. |
| secretFilter.gitleaksConfigPathFrom | string | `""` | Raw path to the custom gitleaks.toml file. Use this to reference an Alloy component |
| secretFilter.includeGeneric | bool | `false` | Include the generic API key rule. |
| secretFilter.inclusionSelector | string | `""` | Loki selector to send processed logs to the secret filter. Anything not matching will be excluded. Example: `{app=="payment-processor"}`. If empty, all pod logs will be sent through the secret filter. |
| secretFilter.partialMask | int | `0` | Show the first N characters of the secret. |
| secretFilter.redactWith | string | `"<REDACTED-SECRET:$SECRET_NAME>"` | String to use to redact secrets. |

### Processing settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| structuredMetadata | object | `{"k8s.pod.name":"k8s.pod.name","pod":"pod","service.instance.id":"service.instance.id"}` | The structured metadata mappings to set. Format: `<key>: <extracted_key>`. Example: structuredMetadata:   component: component   kind: kind   name: name |
