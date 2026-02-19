<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Cluster Metrics

This chart deploys the Cluster Metrics feature of the Kubernetes Monitoring Helm Chart, which uses allow
lists to limit the metrics needed. An allow list is a set of metric names that will be kept, while any metrics
not on the list will be dropped. With [metrics tuning](#metrics-tuning--allow-lists), you can further customize which metrics are collected.

## Usage

```yaml
clusterMetrics:
  enabled: true
```

## How it works

This chart includes the ability to collect metrics from the following:

*   The Kubernetes cluster itself
*   Sources like the Kubelet and cAdvisor
*   Common supporting services like [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) and
    [Node Exporter](https://github.com/prometheus/node_exporter)
*   Systems to capture additional data like Kepler

### Metrics sources

The Cluster Metrics feature of the Kubernetes Monitoring Helm Chart includes the following metric systems and
their default allow lists:

| Metric source                                                                | Gathers information about                                                                    | Allow list                                                                                                                                                                                     |
|------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| API Server                                                                   | Kubernetes API Server                                                                        | NA                                                                                                                                                                                             |
| [cAdvisor](https://github.com/google/cadvisor)                               | Containers on each node                                                                      | [default-allow-lists/cadvisor.yaml](./default-allow-lists/cadvisor.yaml)                                                                                                                       |
| [Kepler](https://sustainable-computing.io/)                                  | Kubernetes cluster                                                                           | [default-allow-lists/kepler.yaml](./default-allow-lists/kepler.yaml)                                                                                                                           |
| Kube Controller Manager                                                      | Kubernetes Controller Manager                                                                | NA                                                                                                                                                                                             |
| Kube Proxy                                                                   | Kube Proxy                                                                                   | NA                                                                                                                                                                                             |
| Kube Scheduler                                                               | Kube Scheduler                                                                               | NA                                                                                                                                                                                             |
| Kubelet                                                                      | Kubernetes information on each node                                                          | [default-allow-lists/kubelet.yaml](./default-allow-lists/kubelet.yaml)                                                                                                                         |
| [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)       | Kubernetes                                                                                   |                                                                                                                                                                                                |
| resources inside the cluster                                                 | [default-allow-lists/kube-state-metrics.yaml](./default-allow-lists/kube-state-metrics.yaml) |                                                                                                                                                                                                |
| [Node Exporter](https://github.com/prometheus/node_exporter)                 | Linux Kubernetes nodes                                                                       | [default-allow-lists/node-exporter.yaml](./default-allow-lists/node-exporter.yaml), [default-allow-lists/node-exporter-integration.yaml](./default-allow-lists/node-exporter-integration.yaml) |
| [Windows Exporter](https://github.com/prometheus-community/windows_exporter) | Windows Kubernetes nodes                                                                     | [default-allow-lists/windows-exporter.yaml](./default-allow-lists/windows-exporter.yaml)                                                                                                       |

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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cost-metrics>
<!-- markdownlint-enable list-marker-space -->

<!-- markdownlint-enable no-bare-urls -->

<!-- markdownlint-disable no-space-in-emphasis -->
## Values

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.kubernetesAPIService | string | `""` | The Kubernetes service. Change this if your cluster DNS is configured differently than the default. |
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |
| global.scrapeClassicHistograms | bool | `false` | Whether to scrape a classic histogram that’s also exposed as a native histogram. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |
| global.scrapeNativeHistograms | bool | `false` | Whether to scrape native histograms. |
| global.scrapeProtocols | list | `["OpenMetricsText1.0.0","OpenMetricsText0.0.1","PrometheusText0.0.4"]` | The protocols to negotiate during a Prometheus metrics scrape, in order of preference. |
| global.scrapeTimeout | string | `"10s"` | The timeout for scraping metrics. |

### OpenCost

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| opencost.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for OpenCost. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| opencost.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for OpenCost. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no __meta* labels are present. |
| opencost.jobLabel | string | `"integrations/opencost"` | The value for the job label. |
| opencost.labelMatchers | object | `{}` | Labels used to select the OpenCost pods. If deploying from telemetry services, this will automatically be populated. |
| opencost.maxCacheSize | string | `100000` | Sets the max_cache_size for the prometheus.relabel component for OpenCost. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| opencost.metricsSource | string | `""` | The name of the metric destination where OpenCost will query for required metrics. Setting this will enable guided setup for required OpenCost parameters. To skip guided setup, set this to "custom". |
| opencost.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| opencost.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| opencost.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from OpenCost to the minimal set required for Kubernetes Monitoring. |
| opencost.namespace | string | `""` | Namespace to locate OpenCost pods. If deploying from telemetry services, this will automatically be populated. |
| opencost.scrapeInterval | string | `60s` | How frequently to scrape metrics from Kepler. Overrides global.scrapeInterval. |
| opencost.scrapeTimeout | string | `10s` | The timeout for scraping OpenCost metrics. |
<!-- markdownlint-enable no-space-in-emphasis -->
