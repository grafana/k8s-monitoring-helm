# cert-manager

<!-- textlint-disable terminology -->
## Values

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for discovered targets of this integration instance. Applied pre-scrape against targets from Kubernetes service discovery, so all `__meta*` labels are present (e.g. `labelmap` from pod annotations). ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| fieldSelectors | list | `[]` | Discover cert-manager instances based on field selectors. |
| labelSelectors | object | `{}` | Discover cert-manager instances based on label selectors. At least one is required. |
| metrics.portName | string | `"http-metrics"` | Name of the port to scrape metrics from. |
| namespaces | list | `[]` | Namespaces to look for cert-manager instances. Will automatically look for cert-manager instances in all namespaces unless specified here |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobLabel | string | `"integrations/cert-manager"` | The value of the job label for scraped metrics and logs |
| name | string | `""` | Name for this cert-manager instance. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for cert-manager prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)). Overrides `global.maxCacheSize`. |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from cert-manager. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from cert-manager. |
<!-- textlint-enable terminology -->
