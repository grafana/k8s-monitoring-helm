# istio

<!-- textlint-disable terminology -->
## Values

### Istiod Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| istiodMetrics.enabled | bool | `true` | Whether to enable metrics collection from Istio . |
| istiodMetrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for MySQL metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| istiodMetrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| istiodMetrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from MySQL Exporter. |
| istiodMetrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from MySQL Exporter. |
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
| sidecarMetrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for MySQL metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| sidecarMetrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| sidecarMetrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from Istio sidecar containers. |
| sidecarMetrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from Istio sidecar containers. |
| sidecarMetrics.sidecarContainerName | string | `"istio-proxy.*"` | The name of the Istio sidecar container. |
| sidecarMetrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| sidecarMetrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| sidecarMetrics.tuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Grafana Alloy to the minimal set required for the Grafana Alloy integration. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| istiodMetrics.namespace | string | `""` |  |
| istiodMetrics.serviceName | string | `"istiod"` |  |
| sidecarMetrics.labelSelectors | object | `{}` |  |
<!-- textlint-enable terminology -->
