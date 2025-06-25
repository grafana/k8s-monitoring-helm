<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Cluster Events

The Cluster Events feature enables the collection of Kubernetes events from the cluster.

## Usage

```yaml
clusterEvents:
  enabled: true
```

## How it works

Events are captured as logs and are annotated with additional metadata to make them easier to search and filter.

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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cluster-events>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Processing settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| excludeLevels | list | `[]` | List of event levels to ignore. e.g. `["Normal", "Warning"]` |
| excludeReasons | list | `[]` | List of event reasons to ignore. e.g. `["Pulling", "Started"]` |
| extraLogProcessingStages | string | `""` | Stage blocks to be added to the loki.process component for cluster events. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| includeLevels | list | `[]` | List of event levels to include (`[]` means allow all event levels). e.g. `["Normal", "Warning"]` |
| includeReasons | list | `[]` | List of event reasons to include (`[]` means allow all event reasons). e.g. `["Failed"]` |
| jobLabel | string | `"integrations/kubernetes/eventhandler"` | The value for the job label. |
| labelsToKeep | list | `["job","level","namespace","node","source","reason"]` | The list of labels to keep on the logs, all other pipeline labels will be dropped. |
| structuredMetadata | object | `{"name":"name"}` | The structured metadata mappings to set. To not set any structured metadata, set this to an empty object (e.g. `{}`) Format: `<key>: <extracted_key>`. Example: structuredMetadata:   component: component   kind: kind   name: name |

### Gather settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| excludeNamespaces | list | `[]` | List of namespaces to ignore events for. |
| logFormat | string | `"logfmt"` | Log format used to forward cluster events. Allowed values: `logfmt` (default), `json`. |
| namespaces | list | `[]` | List of namespaces to watch for events (`[]` means all namespaces) |
