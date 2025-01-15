<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# feature-node-logs

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)
Kubernetes Observability feature for gathering Cluster Node logs.

The Node Logs feature enables the collection of logs from Kubernetes Cluster Nodes. This is useful for understanding the
health and performance of the nodes in your cluster. Currently, it gathers logs from the journald service from a
filterable list of units.

## journald

Gathering logs from journald requires a volume mount to the Node's `/var/log/journal` directory.

You can define a list of units to filter logs from. By default, the feature will collect logs from all units.

```yaml
nodeLogs:
  journal:
    units:
      - kubelet.service
      - containerd.service
```

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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-node-logs>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Journal Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraDiscoveryRules | string | `""` | Rule blocks to be added used with the loki.source.journal component for journal logs. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) **Note:** Many field names from journald start with an `_`, such as `_systemd_unit`. The final internal label name would be `__journal__systemd_unit`, with two underscores between `__journal` and `systemd_unit`. |
| extraLogProcessingStages | string | `""` | Stage blocks to be added to the loki.process component for journal logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| journal.formatAsJson | bool | `false` | Whether to forward the original journal entry as JSON. |
| journal.jobLabel | string | `"integrations/kubernetes/journal"` | The value for the job label for journal logs. |
| journal.maxAge | string | `"8h"` | The path to the journal logs on the worker node. |
| journal.path | string | `"/var/log/journal"` | The path to the journal logs on the worker node. |
| journal.units | list | `[]` | The list of systemd units to keep scraped logs from. If empty, all units are scraped. |

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |

### Processing settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| labelsToKeep | list | `["instance","job","level","name","unit","service_name","source"]` | The list of labels to keep on the logs, all other pipeline labels will be dropped. |
| structuredMetadata | object | `{}` | The structured metadata mappings to set. To not set any structured metadata, set this to an empty object (e.g. `{}`) Format: `<key>: <extracted_key>`. Example: structuredMetadata:   detected_level: level |
