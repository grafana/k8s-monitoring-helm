<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Host Metrics

This chart deploys the Host Metrics feature of the Kubernetes Monitoring Helm chart, which uses allow lists to limit the
metrics needed. An allow list is a set of metric names that will be kept, while any metrics not on the list will be
dropped. With [metrics tuning](#metrics-tuning--allow-lists), you can further customize which metrics are collected.

## Usage

```yaml
hostMetrics:
  enabled: true
  node-exporter:
    enabled: true
```

## How it works

This chart includes the ability to collect metrics from the following:

*   Node Exporter for metrics from Linux hosts
*   Windows Exporter for metrics from Windows hosts
*   Kepler for energy metrics

### Metrics sources

The Host Metrics feature of the Kubernetes Monitoring Helm Chart includes the following metric systems and
their default allow lists:

| Metric source                                                                | Gathers information about | Allow list                                                                                                                                                                                     |
|------------------------------------------------------------------------------|---------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Kepler](https://sustainable-computing.io/)                                  | Kubernetes cluster        | [default-allow-lists/kepler.yaml](./default-allow-lists/kepler.yaml)                                                                                                                           |
| [Node Exporter](https://github.com/prometheus/node_exporter)                 | Linux Kubernetes nodes    | [default-allow-lists/node-exporter.yaml](./default-allow-lists/node-exporter.yaml), [default-allow-lists/node-exporter-integration.yaml](./default-allow-lists/node-exporter-integration.yaml) |
| [Windows Exporter](https://github.com/prometheus-community/windows_exporter) | Windows Kubernetes nodes  | [default-allow-lists/windows-exporter.yaml](./default-allow-lists/windows-exporter.yaml)                                                                                                       |

## Metrics tuning and allow lists

For any metric source, you can adjust the amount of metrics being scraped and their labels to limit the number of metrics delivered to your destinations. Many of the metric sources have a default allow list. The allow list for a metric source is designed to return a useful, but minimal set of metrics for typical use cases. Some metrics sources have an integration allow list, which contains even more metrics for diving into the details of the source itself.

To control metrics with allow lists or label filters, use the `metricsTuning` section in the values file.

```yaml
<metric source>:
  metricsTuning:
    useDefaultAllowList: <boolean>      # Use the allow list for this metric source
    useIntegrationAllowList: <boolean>  # Use the integration allow list for this metric source
    includeMetrics: [<string>]          # Metrics to be kept
    excludeMetrics: [<string>]          # Metrics to be dropped
```

The behavior of the combination of these settings is shown in this table:

| Allow list | includeMetrics   | excludeMetrics           | Result                                                                                                                                  |
|------------|------------------|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| true       | `[]`             | `[]`                     | Use the allow list metric list                                                                                                          |
| false      | `[]`             | `[]`                     | No filter, keep all metrics                                                                                                             |
| true       | `[my_metric]`    | `[]`                     | Use the allow list metric list with an additional metric                                                                                |
| false      | `[my_metric_.*]` | `[]`                     | *Only* keep metrics that start with `my_metric_`                                                                                        |
| true       | `[]`             | `[my_metric_.*]`         | Use the allow list metric filter, but exclude anything that starts with `my_metric_`                                                    |
| false      | `[]`             | `[my_metric_.*]`         | Keep all metrics except anything that starts with `my_metric_`                                                                          |
| true       | `[my_metric_.*]` | `[other_metric_.*]`      | Use the allow list metric filter, and keep anything that starts with `my_metric_`, but remove anything that starts with `other_metric_` |
| false      | `[my_metric_.*]` | `[my_metric_not_needed]` | *Only* keep metrics that start with `my_metric_`, but remove any that are named `my_metric_not_needed`                                  |

## Relabeling rules

You can also use relabeling rules to take any action on the metrics allow list, such as to filter based on a label.
To do so, use `extraMetricProcessingRules` section in the values file to add arbitrary relabeling rules.

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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-host-metrics>
<!-- markdownlint-enable list-marker-space -->

<!-- markdownlint-enable no-bare-urls -->

<!-- markdownlint-disable no-space-in-emphasis -->
## Values

### Energy Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| energyMetrics.enabled | bool | `false` | Deploy and scrape energy metrics. |
| energyMetrics.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kepler. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| energyMetrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kepler. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no __meta* labels are present. |
| energyMetrics.jobLabel | string | `"integrations/kepler"` | The value for the job label. |
| energyMetrics.labelMatchers | object | `{}` | Label matchers used to select the Kepler pods. If deploying from telemetry services, this will automatically be populated. |
| energyMetrics.maxCacheSize | string | `100000` | Sets the max_cache_size for the prometheus.relabel component for Kepler. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| energyMetrics.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| energyMetrics.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| energyMetrics.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kepler to the minimal set required for Kubernetes Monitoring. |
| energyMetrics.namespace | string | `""` | Namespace to locate Kepler pods. If deploying from telemetry services, this will automatically be populated. |
| energyMetrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from Kepler. Overrides global.scrapeInterval. |
| energyMetrics.scrapeTimeout | string | `10s` | The timeout for scraping Kepler metrics. |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.kubernetesAPIService | string | `""` | The Kubernetes service. Change this if your cluster DNS is configured differently than the default. |
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.scrapeClassicHistograms | bool | `false` | Whether to scrape a classic histogram that’s also exposed as a native histogram. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |
| global.scrapeNativeHistograms | bool | `false` | Whether to scrape native histograms. |
| global.scrapeProtocols | list | `["OpenMetricsText1.0.0","OpenMetricsText0.0.1","PrometheusText0.0.4"]` | The protocols to negotiate during a Prometheus metrics scrape, in order of preference. |
| global.scrapeTimeout | string | `"10s"` | The timeout for scraping metrics. |

### Linux Host

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| linuxHosts.bearerTokenFile | string | `""` | The bearer token file to use when scraping metrics from Node Exporter. |
| linuxHosts.enabled | bool | `false` | Scrape Linux host metrics. |
| linuxHosts.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for discovering Node Exporter pods. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| linuxHosts.extraMetricProcessingRules | string | `""` | Rule blocks to be added for processing Linux host metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| linuxHosts.jobLabel | string | `"integrations/node_exporter"` | The value for the job label. |
| linuxHosts.labelMatchers | object | `{}` | Labels used to select the Node Exporter pods. If deploying from telemetry services, this will automatically be populated. |
| linuxHosts.maxCacheSize | string | `100000` | Sets the max_cache_size for the Node Exporter prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| linuxHosts.metricsTuning.dropMetricsForFilesystem | list | `["ramfs","tmpfs"]` | Drop metrics for the given filesystem types |
| linuxHosts.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| linuxHosts.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| linuxHosts.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring. |
| linuxHosts.metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring as well as the Node Exporter integration. |
| linuxHosts.namespace | string | `""` | Namespace to locate Node Exporter pods. If deploying from telemetry services, this will automatically be populated. |
| linuxHosts.scheme | string | `"http"` | The scrape scheme for Linux host metrics. |
| linuxHosts.scrapeInterval | string | `60s` | How frequently to scrape Linux host metrics. |
| linuxHosts.scrapeTimeout | string | `10s` | The timeout for scraping Linux host metrics. |

### Windows Host

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| windowsHosts.bearerTokenFile | string | `""` | The bearer token file to use when scraping metrics from Windows Exporter. |
| windowsHosts.enabled | bool | `false` | Scrape node metrics |
| windowsHosts.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Windows Exporter. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| windowsHosts.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Windows Exporter metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| windowsHosts.jobLabel | string | `"integrations/windows-exporter"` | The value for the job label. |
| windowsHosts.labelMatchers | object | `{}` | Labels used to select the Windows Exporter pods. If deploying from telemetry services, this will automatically be  # populated. |
| windowsHosts.maxCacheSize | string | `100000` | Sets the max_cache_size for the Windows Exporter prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| windowsHosts.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| windowsHosts.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| windowsHosts.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Windows Exporter to the minimal set required for Kubernetes Monitoring. |
| windowsHosts.namespace | string | `""` | Namespace to locate Windows Exporter pods. If deploying from telemetry services, this will automatically be  # populated. |
| windowsHosts.scheme | string | `"http"` | The scrape scheme for Windows host metrics. |
| windowsHosts.scrapeInterval | string | `60s` | How frequently to scrape Windows host metrics. |
| windowsHosts.scrapeTimeout | string | `10s` | The timeout for scraping Windows host metrics. |
<!-- markdownlint-enable no-space-in-emphasis -->
