# cert-manager

## Values

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| field_selectors | list | `[]` | Discover cert-manager instances based on field selectors. |
| labelSelectors | object | `{}` | Discover cert-manager instances based on label selectors. Will automatically set a matcher for `app.kubernetes.io/name: <name>` unless set here. |
| namespaces | list | `[]` | Namespaces to look for cert-manager instances. |
| portName | string | `"http-metrics"` | Name of the port to scrape metrics from. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobName | string | `"integrations/cert-manager"` | The value of the job label for scraped metrics. |
| scrapeInterval | string | `60s` | How frequently to scrape metrics from Windows Exporter. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| maxCacheSize | string | `100000` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | Name for this cert-manager instance. |
