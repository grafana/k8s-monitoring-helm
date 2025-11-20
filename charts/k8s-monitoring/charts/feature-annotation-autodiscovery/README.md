<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Annotation Autodiscovery

The annotation-based autodiscovery feature adds scrape targets based on Kubernetes annotations.

## Usage

```yaml
annotationAutodiscovery:
  enabled: true
```

## How it works

With this feature enabled, any Kubernetes Pods or Services with the `k8s.grafana.com/scrape` annotation set to `true` will be automatically discovered
and scraped by the collector.

You can use several other annotations to customize the behavior of the scrape configuration, such as:

*   `k8s.grafana.com/job`: The value to use for the `job` label.
*   `k8s.grafana.com/instance`: The value to use for the `instance` label.
*   `k8s.grafana.com/metrics.container`: The name of the container within the Pod to scrape for metrics. This is used to target a specific container within a Pod that has multiple containers.
*   `k8s.grafana.com/metrics.path`: The path to scrape for metrics. Defaults to `/metrics`.
*   `k8s.grafana.com/metrics.portNumber`: The port on the Pod or Service to scrape for metrics. This is used to target a specific port by its number, rather than all ports.
*   `k8s.grafana.com/metrics.portName`: The named port on the Pod or Service to scrape for metrics. This is used to target a specific port by its name, rather than all ports.
*   `k8s.grafana.com/metrics.scheme`: The scheme to use when scraping metrics. Defaults to `http`.
*   `k8s.grafana.com/metrics.param`: Allows for setting HTTP parameters when calling the scrape endpoint. Use with `k8s.grafana.com/metrics.param_<key>="<value>"`.
*   `k8s.grafana.com/metrics.scrapeInterval`: The scrape interval to use when scraping metrics. Defaults to `60s`.
*   `k8s.grafana.com/metrics.scrapeTimeout`: The scrape timeout to use when scraping metrics. Defaults to `10s`.

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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-annotation-autodiscovery>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Annotations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations.instance | string | `"k8s.grafana.com/instance"` | Annotation for overriding the instance label |
| annotations.job | string | `"k8s.grafana.com/job"` | Annotation for overriding the job label |
| annotations.metricsContainer | string | `"k8s.grafana.com/metrics.container"` | Annotation for selecting the specific container to scrape. |
| annotations.metricsParam | string | `"k8s.grafana.com/metrics.param"` | Annotation for setting `__param_<key>` parameters when scraping. Example: `k8s.grafana.com/metrics.param_key: "value"`. |
| annotations.metricsPath | string | `"k8s.grafana.com/metrics.path"` | Annotation for setting or overriding the metrics path. If not set, it defaults to /metrics |
| annotations.metricsPortName | string | `"k8s.grafana.com/metrics.portName"` | Annotation for setting the metrics port by name. |
| annotations.metricsPortNumber | string | `"k8s.grafana.com/metrics.portNumber"` | Annotation for setting the metrics port by number. |
| annotations.metricsScheme | string | `"k8s.grafana.com/metrics.scheme"` | Annotation for setting the metrics scheme, default: http. |
| annotations.metricsScrapeInterval | string | `"k8s.grafana.com/metrics.scrapeInterval"` | Annotation for overriding the scrape interval for this service or pod. Value should be a duration like "15s, 1m". Overrides metrics.autoDiscover.scrapeInterval |
| annotations.metricsScrapeTimeout | string | `"k8s.grafana.com/metrics.scrapeTimeout"` | Annotation for overriding the scrape timeout for this service or pod. Value should be a duration like "15s, 1m". Overrides metrics.autoDiscover.scrapeTimeout |
| annotations.scrape | string | `"k8s.grafana.com/scrape"` | Annotation for enabling scraping for this service or pod. Value should be either "true" or "false" |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bearerToken | object | `{"enabled":true,"token":"/var/run/secrets/kubernetes.io/serviceaccount/token"}` | Sets bearer_token_file line in the prometheus.scrape annotation_autodiscovery. |
| scrapeInterval | string | 60s | How frequently to scrape metrics from discovered pods and services. Only used if the `k8s.grafana.com/metrics.scrapeInterval` annotation is not set. Overrides global.scrapeInterval |
| scrapeTimeout | string | 10s | The scrape timeout for discovered pods and services. Only used if the `k8s.grafana.com/metrics.scrapeTimeout` annotation is not set. Overrides global.scrapeTimeout |

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| excludeNamespaces | list | `[]` | The list of namespaces to exclude from autodiscovery. |
| extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for discovered pods and services. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| labelSelectors | object | `{}` | Filter the list of discovered pods and services by labels. Example: `labelSelectors: { 'app': 'myapp' }` will only discover pods and services with the label `app=myapp`. Example: `labelSelectors: { 'app': ['myapp', 'myotherapp'] }` will only discover pods and services with the label `app=myapp` or `app=myotherapp`. |
| namespaces | list | `[]` | The list of namespaces to include in autodiscovery. If empty, all namespaces are included. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for discovered pods and services. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.scrapeClassicHistograms | bool | `false` | Whether to scrape a classic histogram that’s also exposed as a native histogram. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |
| global.scrapeNativeHistograms | bool | `false` | Whether to scrape native histograms. |
| global.scrapeProtocols | list | `["OpenMetricsText1.0.0","OpenMetricsText0.0.1","PrometheusText0.0.4"]` | The protocols to negotiate during a Prometheus metrics scrape, in order of preference. |
| global.scrapeTimeout | string | `"10s"` | The timeout for scraping metrics. |

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

### Pod Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pods.enabled | bool | `true` | Enable discovering Pods with annotations. |
| pods.labelSelectors | object | `{}` | Filter the list of discovered Pods by labels. Example: `labelSelectors: { 'app': 'myapp' }` will only discover Pods with the label `app=myapp`. Example: `labelSelectors: { 'app': ['myapp', 'myotherapp'] }` will only discover Pods with the label `app=myapp` or `app=myotherapp`. |

### Pod Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pods.labels | object | `{}` | Add labels to metrics from discovered Pods. Runs during discovery, so __meta_ labels are available. See the [documentation](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.kubernetes/#pod-role) for the full list of meta labels. |
| pods.staticLabels | object | `{}` | Metric labels to set with static data for discovered Pods. |
| pods.staticLabelsFrom | object | `{}` | Static labels to set on metrics from discovered Pods, not quoted so it can reference config components. |

### Services

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| services.enabled | bool | `true` | Enable discovering Services with annotations. |

### Service Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| services.labelSelectors | object | `{}` | Filter the list of discovered Services by labels. Example: `labelSelectors: { 'app': 'myapp' }` will only discover Services with the label `app=myapp`. Example: `labelSelectors: { 'app': ['myapp', 'myotherapp'] }` will only discover Services with the label `app=myapp` or `app=myotherapp`. |

### Service Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| services.labels | object | `{}` | Add labels to metrics from discovered Services. Run during discovery, so __meta_ labels are available. See the [documentation](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.kubernetes/#service-role) for the full list of meta labels. |
| services.staticLabels | object | `{}` | Metric labels to set with static data for discovered Services. |
| services.staticLabelsFrom | object | `{}` | Static labels to set on metrics from discovered Services, not quoted so it can reference config components. |
