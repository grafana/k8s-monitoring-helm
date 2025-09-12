# Grafana Alloy Integration

This integration captures the metrics and logs to understand the health and performance of your Grafana
Alloy instances.

## Values

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fieldSelectors | list | `[]` | Discover Alloy instances based on field selectors. |
| labelSelectors | object | `{}` | Discover Alloy instances based on label selectors. At least one is required. |
| metrics.portName | string | `"http-metrics"` | Name of the port to scrape metrics from. |
| namespaces | list | `[]` | Namespaces to look for Alloy instances in. Will automatically look for Alloy instances in all namespaces unless specified here |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobLabel | string | `"integrations/alloy"` | The value of the job label for scraped metrics and logs |
| name | string | `""` | Name for this Alloy instance. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.tuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Grafana Alloy to the minimal set required for the Grafana Alloy integration. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from Alloy. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from Alloy. |

## Enabling

To enable this integration, create an instance with the Alloy names:

```yaml
integrations:
  alloy:
    instances:
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: [alloy-metrics, alloy-singleton, alloy-logs]
```

Multiple instances can be used if you wish to set different configurations for each Alloy integration. For example, if
you want full health and performance metrics for the alloy-metrics instance, but only the `alloy_build_info` metric for
the other Alloy instances, you can use the following configuration:

```yaml
integrations:
  alloy:
    instances:
      - name: alloy-metrics
        labelSelectors:
          app.kubernetes.io/name: alloy-metrics
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: [alloy-logs, alloy-singleton]
        metrics:
          tuning:
            useDefaultAllowList: false
            includedMetrics: [alloy_build_info]
```
