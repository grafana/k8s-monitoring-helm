# istio

<!-- textlint-disable terminology -->
## Values

### Istiod Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| istiodMetrics.enabled | bool | `true` | Whether to enable metrics collection from Istiod. |
| istiodMetrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Istiod. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| istiodMetrics.labelSelectors | object | `{}` | Additional Kubernetes label selectors applied to the Istiod service. |
| istiodMetrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| istiodMetrics.namespace | string | `""` | The namespace where the Istiod Kubernetes service is deployed. |
| istiodMetrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from Istiod. |
| istiodMetrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from Istiod. |
| istiodMetrics.serviceName | string | `"istiod"` | The name of the Istiod Kubernetes service. |
| istiodMetrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| istiodMetrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobLabel | string | `"integration/istio"` | The value of the job label for scraped metrics and logs |
| name | string | `""` | Name for this Istio integration instance. |

### Sidecar Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| sidecarMetrics.enabled | bool | `true` | Whether to enable metrics collection from Istio sidecar containers. |
| sidecarMetrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Istio sidecar metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| sidecarMetrics.labelSelectors | object | `{}` | Label selectors to be used when choosing pods with the Istio sidecar. |
| sidecarMetrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| sidecarMetrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from Istio sidecar containers. |
| sidecarMetrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from Istio sidecar containers. |
| sidecarMetrics.sidecarContainerName | string | `"istio-proxy.*"` | The name of the Istio sidecar container. |
| sidecarMetrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| sidecarMetrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| sidecarMetrics.tuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Istio sidecar to the minimal set required for the Istio integration. |
<!-- textlint-enable terminology -->
