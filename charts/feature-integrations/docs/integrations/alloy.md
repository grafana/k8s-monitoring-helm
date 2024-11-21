# alloy

## Values

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| labelSelectors | object | `{}` | Discover Alloy instances based on label selectors. Will automatically set a matcher for `app.kubernetes.io/name: <name>` unless set here. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Grafana Alloy to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from Grafana Alloy to the minimal set required for Kubernetes Monitoring as well as the Grafana Alloy integration. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | Name for this Alloy instance. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| scrapeInterval | string | `60s` | How frequently to scrape metrics from Alloy. |
