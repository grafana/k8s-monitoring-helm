# Grafana Tempo Integration

This integration captures the metrics and logs to understand the health and performance of your Grafana Tempo instances.

## Values

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fieldSelectors | list | `[]` | Discover Tempo instances based on field selectors. |
| labelSelectors | object | `{"app.kubernetes.io/name":["tempo","enterprise-traces"]}` | Discover Tempo instances based on label selectors. |
| metrics.portName | string | `"http-metrics"` | Name of the port to scrape metrics from. |
| namespaces | list | `[]` | Namespaces to look for Tempo instances in. Will automatically look for Tempo instances in all namespaces unless specified here |

### Logs Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `true` | Whether to enable special processing of Tempo pod logs. |
| logs.tuning.dropLogLevels | list | `["debug"]` | The log levels to drop. Will automatically keep all log levels unless specified here. |
| logs.tuning.excludeLines | list | `[]` | Line patterns (valid RE2 regular expression)to exclude from the logs. |
| logs.tuning.scrubTimestamp | bool | `true` | Whether the timestamp should be scrubbed from the log line |
| logs.tuning.structuredMetadata | object | `{}` | The structured metadata mappings to set. To not set any structured metadata, set this to an empty object (e.g. `{}`) |
| logs.tuning.timestampFormat | string | `"RFC3339Nano"` | The timestamp format to use for the log line, if not set the default timestamp which is the collection will be used for the log line |

### Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.enabled | bool | `true` | Whether to enable metrics collection from Tempo. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.tuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Grafana Tempo to the minimal set required for the Grafana Tempo integration. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from Tempo. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from Tempo. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | Name for this Tempo instance. |
