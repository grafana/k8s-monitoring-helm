<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring-feature-prometheus-operator-objects

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)
Gathers metrics using Prometheus Operator Objects

The Prometheus Operator Objects feature enables the discovery, processing, and utilization of certain Prometheus
Operator objects. Currently, this feature supports the following objects:

| Object Type | Description |
|-------------|-------------|
| [ServiceMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.ServiceMonitor) | A ServiceMonitor defines how to scrape metrics from Kubernetes Services. |
| [PodMonitor](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.PodMonitor) | A PodMonitor defines how to scrape metrics from Kubernetes Pods. |
| [Probe](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.Probe) | A Probe defines how to scrape metrics from prober exporters. |

## Testing

This chart contains unit tests to verify the generated configuration. A hidden value, `deployAsConfigMap`, will render
the generated configuration into a ConfigMap object. This ConfigMap is not used during regular operation, but it is
useful for showing the outcome of a given values file.

The unit tests use this to create an object with the configuration that can be asserted against. To run the tests, use
`helm test`.

Actual integration testing in a live environment should be done in the main [k8s-monitoring](../k8s-monitoring) chart.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-prometheus-operator-objects>
<!-- markdownlint-enable list-marker-space -->

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://prometheus-community.github.io/helm-charts | crds(prometheus-operator-crds) | 16.0.0 |
<!-- markdownlint-enable no-bare-urls -->
## Values

### CRDs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| crds.deploy | bool | `false` | Deploy the Prometheus Operator CRDs. |

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |

### PodMonitors

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| podMonitors.enabled | bool | `true` | Enable discovery of Prometheus Operator PodMonitor objects. |
| podMonitors.extraDiscoveryRules | string | `""` | Rule blocks to be added to the prometheus.operator.podmonitors component for PodMonitors. These relabeling rules are applied pre-scrape against the targets from service discovery. The relabelings defined in the PodMonitor object are applied first, then these relabelings are applied. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| podMonitors.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for PodMonitor objects. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| podMonitors.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| podMonitors.namespaces | list | `[]` | Which namespaces to look for PodMonitor objects. |
| podMonitors.scrapeInterval | string | 60s | How frequently to scrape metrics from PodMonitor objects. Only used if the PodMonitor does not specify the scrape interval. Overrides global.scrapeInterval |
| podMonitors.selector | string | `""` | Selector to filter which PodMonitor objects to use. |

### Probes

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| probes.enabled | bool | `true` | Enable discovery of Prometheus Operator Probe objects. |
| probes.extraDiscoveryRules | string | `""` | Rule blocks to be added to the prometheus.operator.probes component for Probes. These relabeling rules are applied pre-scrape against the targets from service discovery. The relabelings defined in the PodMonitor object are applied first, then these relabelings are applied. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| probes.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Probe objects. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| probes.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| probes.namespaces | list | `[]` | Which namespaces to look for Probe objects. |
| probes.scrapeInterval | string | 60s | How frequently to scrape metrics from Probe objects. Only used if the Probe does not specify the scrape interval. Overrides global.scrapeInterval |
| probes.selector | string | `""` | Selector to filter which Probes objects to use. |

### ServiceMonitors

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| serviceMonitors.enabled | bool | `true` | Enable discovery of Prometheus Operator ServiceMonitor objects. |
| serviceMonitors.extraDiscoveryRules | string | `""` | Rule blocks to be added to the prometheus.operator.probes component for Probes. These relabeling rules are applied pre-scrape against the targets from service discovery. The relabelings defined in the PodMonitor object are applied first, then these relabelings are applied. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| serviceMonitors.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for ServiceMonitor objects. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| serviceMonitors.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| serviceMonitors.namespaces | list | `[]` | Which namespaces to look for ServiceMonitor objects. |
| serviceMonitors.scrapeInterval | string | 60s | How frequently to scrape metrics from ServiceMonitor objects. Only used if the ServiceMonitor does not specify the scrape interval. Overrides global.scrapeInterval |
| serviceMonitors.selector | string | `""` | Selector to filter which ServiceMonitor objects to use. |
