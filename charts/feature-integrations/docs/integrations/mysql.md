# mysql

## Values

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| labelSelectors | object | `{}` | Discover MySQL Exporter instances based on label selectors, if not using the exporter |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | Name for this MySQL instance. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| scrapeInterval | string | `60s` | How frequently to scrape metrics from MySQL Exporter. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| exporter.collectors[0] | string | `"heartbeat"` |  |
| exporter.collectors[1] | string | `"mysql.user"` |  |
| exporter.dataSource.host | string | `""` |  |
| exporter.dataSource.password | string | `""` |  |
| exporter.dataSource.port | int | `3306` |  |
| exporter.dataSource.username | string | `""` |  |
| exporter.dataSourceName | string | `""` |  |
| exporter.enabled | bool | `true` |  |
