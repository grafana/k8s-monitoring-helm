# etcd

## Values

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| field_selectors | list | `[]` | Discover etcd instances based on field selectors. |
| labelSelectors | object | `{}` | Discover etcd instances based on label selectors. At least one is required. |
| metrics.portName | string | `"metrics"` | Name of the port to scrape metrics from. |
| namespaces | list | `[]` | Namespaces to look for etcd instances. Will automatically look for etcd instances in all namespaces unless specified here |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobLabel | string | `"integrations/etcd"` | The value of the job label for scraped metrics and logs |
| name | string | `""` | Name for this etcd instance. |

### Logs Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `false` | Whether to enable special processing of etcd pod logs. |

### Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.enabled | bool | `true` | Whether to enable metrics collection from etcd. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from Windows Exporter. |
