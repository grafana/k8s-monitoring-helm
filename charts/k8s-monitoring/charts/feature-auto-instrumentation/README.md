<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Auto-Instrumentation

The auto-instrumentation feature deploys Grafana Beyla to automatically instrument programs running on this cluster using eBPF.

## Usage

```yaml
autoInstrumentation:
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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-auto-instrumentation>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://grafana.github.io/helm-charts | beyla | 1.9.9 |
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->
<!-- markdownlint-disable no-space-in-emphasis -->
## Values

### Beyla

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| beyla.config.data | object | `{"attributes":{"kubernetes":{"enable":true}},"internal_metrics":{"prometheus":{"path":"/internal/metrics"}},"prometheus_export":{"features":["application","network","application_service_graph","application_span","application_host"],"path":"/metrics"}}` | The configuration for Grafana Beyla Some sections will be set automatically, such as the cluster name. Others will be modified depending on the value of beyla.preset. |
| beyla.deliverTracesToApplicationObservability | bool | `true` | Whether Beyla should automatically deliver traces to the Application Observability feature. When enabled, traces will be sent to the OTLP receiver if Application Observability is configured. When disabled, only metrics (RED metrics) from the instrumented applications will be collected from Beyla, and traces will not be automatically delivered. |
| beyla.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Beyla. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| beyla.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Beyla. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no __meta* labels are present. |
| beyla.labelMatchers | object | `{"app.kubernetes.io/name":"beyla"}` | Label matchers used to select the Beyla pods for scraping metrics. |
| beyla.maxCacheSize | string | 100000 | Sets the max_cache_size for the prometheus.relabel component for Beyla. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| beyla.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| beyla.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| beyla.preset | string | `"application"` | The configuration preset to use. Valid options are "application" or "network". |
| beyla.scrapeInterval | string | 60s | How frequently to scrape metrics from Beyla. Overrides metrics.scrapeInterval |
| beyla.service | object | `{"targetPort":9090}` | The port number for the Beyla service. |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |
| global.scrapeClassicHistograms | bool | `false` | Whether to scrape a classic histogram that’s also exposed as a native histogram. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |
| global.scrapeNativeHistograms | bool | `false` | Whether to scrape native histograms. |
| global.scrapeProtocols | list | `["OpenMetricsText1.0.0","OpenMetricsText0.0.1","PrometheusText0.0.4"]` | The protocols to negotiate during a Prometheus metrics scrape, in order of preference. |
<!-- markdownlint-enable no-space-in-emphasis -->
