# Grafana Mimir Integration

This integration captures the metrics and logs to understand the health and performance of your Grafana Mimir instances.

## Values

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fieldSelectors | list | `[]` | Discover Mimir instances based on field selectors. |
| labelSelectors | object | `{"app.kubernetes.io/name":"mimir"}` | Discover Mimir instances based on label selectors. |
| namespaces | list | `[]` | Namespaces to look for Mimir instances in. Will automatically look for Mimir instances in all namespaces unless specified here |

### Logs Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `true` | Whether to enable special processing of Mimir pod logs. |
| logs.tuning.dropLogLevels | list | `["debug"]` | The log levels to drop. Will automatically keep all log levels unless specified here. |
| logs.tuning.excludeLines | list | `[]` | Line patterns (valid RE2 regular expression)to exclude from the logs. |
| logs.tuning.scrubTimestamp | bool | `true` | Whether the timestamp should be scrubbed from the log line |
| logs.tuning.structuredMetadata | object | `{}` | The structured metadata mappings to set. To not set any structured metadata, set this to an empty object (e.g. `{}`) |
| logs.tuning.timestampFormat | string | `"RFC3339Nano"` | The timestamp format to use for the log line, if not set the default timestamp which is the collection will be used for the log line |

### Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.enabled | bool | `true` | Whether to enable metrics collection from Mimir. |
| metrics.portName | string | `"http-metrics"` | Name of the port to scrape metrics from. |
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from Mimir. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.tuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Grafana Mimir to the minimal set required for the Grafana Mimir integration. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | Name for this Mimir instance. |
