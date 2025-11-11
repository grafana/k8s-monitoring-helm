# mysql

## Values

### Data Source Connection

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dataSource.auth.password | string | `""` | The password to use for the MySQL connection. |
| dataSource.auth.passwordFrom | string | `""` | Raw config for accessing the password. |
| dataSource.auth.passwordKey | string | `"password"` | The key for storing the password in the secret. |
| dataSource.auth.username | string | `""` | The username to use for the MySQL connection. |
| dataSource.auth.usernameFrom | string | `""` | Raw config for accessing the username. |
| dataSource.auth.usernameKey | string | `"username"` | The key for storing the username in the secret. |
| dataSource.host | string | `""` | The MySQL host to connect to. |
| dataSource.port | int | `3306` | The MySQL port to connect to. |
| dataSource.protocol | string | `""` | The MySQL protocol type. |
| dataSource.rawString | string | `""` | The data source string to use for the MySQL Exporter. |

### MySQL Exporter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| exporter.collectors | object | `{"heartbeat":{"enabled":true},"mysqlUser":{"enabled":true,"privileges":false}}` | The list of collectors to enable for the MySQL Exporter ([Documentation](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.mysql/#supported-collectors)). |
| exporter.enabled | bool | `true` | Whether to database statistic metrics. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobLabel | string | `"integration/mysql"` | The value of the job label for scraped metrics and logs |
| name | string | `""` | Name for this MySQL instance. |

### Logs Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `true` | Whether to enable special processing of MySQL pod logs. |

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.labelSelectors | object | `{}` | Discover MySQL pods based on label selectors. At least one is required. |
| logs.namespaces | list | `[]` | The namespaces to look for MySQL pods in. Will automatically look for MySQL pods in all namespaces unless specified here |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for MySQL metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from MySQL Exporter. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from MySQL Exporter. |

### Query Analysis

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| queryAnalysis.allowUpdatePerformanceSchemaSettings | bool | `false` | Whether to allow updates to performance_schema settings in any collector. |
| queryAnalysis.enabled | bool | `true` | Whether to gather table, schema, and query information from the database. |

### Query Analysis - Collectors

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| queryAnalysis.collectors.explainPlans.collectInterval | string | `"1m"` | How frequently to collect explain plans information from the database. |
| queryAnalysis.collectors.explainPlans.enabled | bool | `false` | Enable collection of explain plans information. |
| queryAnalysis.collectors.explainPlans.excludeSchemas | list | `[]` | List of schemas to exclude from explain plan collection. |
| queryAnalysis.collectors.explainPlans.initialLookback | string | `"24h"` | How far back to look for explain plan queries on the first collection interval. |
| queryAnalysis.collectors.explainPlans.perCollectRatio | float | `1` | Ratio of explain plan queries to collect per collect interval. |
| queryAnalysis.collectors.locks.collectInterval | string | `"1m"` | How frequently to collect lock information from the database. |
| queryAnalysis.collectors.locks.enabled | bool | `false` | Enable collection of lock information. |
| queryAnalysis.collectors.locks.threshold | string | `"1s"` | Threshold for locks to be considered slow. Locks that exceed this duration are logged. |
| queryAnalysis.collectors.queryDetails.collectInterval | string | `"1m"` | How frequently to collect query information from the database. |
| queryAnalysis.collectors.queryDetails.enabled | bool | `true` | Enable collection of query information. |
| queryAnalysis.collectors.querySamples.autoEnableSetupConsumers | bool | `false` | Whether to enable some specific performance_schema.setup_consumers settings. |
| queryAnalysis.collectors.querySamples.collectInterval | string | `"1m"` | How frequently to collect query samples from the database. |
| queryAnalysis.collectors.querySamples.enabled | bool | `true` | Enable collection of query samples. |
| queryAnalysis.collectors.querySamples.setupConsumersCheckInterval | string | `"1h"` | How frequently to check if setup_consumers are correctly enabled. |
| queryAnalysis.collectors.schemaDetails.cacheEnabled | bool | `false` | Whether to enable caching of table definitions. |
| queryAnalysis.collectors.schemaDetails.cacheSize | int | `256` | Table definitions cache size. |
| queryAnalysis.collectors.schemaDetails.cacheTTL | string | `"10m"` | Table definitions cache TTL. |
| queryAnalysis.collectors.schemaDetails.collectInterval | string | `"1m"` | How frequently to collect schemas and tables from information_schema. |
| queryAnalysis.collectors.schemaDetails.enabled | bool | `true` | Enable collection of schemas and tables from information_schema. |
| queryAnalysis.collectors.setupConsumers.collectInterval | string | `"1m"` | How frequently to collect performance_schema.setup_consumers information from the database. |
| queryAnalysis.collectors.setupConsumers.enabled | bool | `true` | Enable collection of performance_schema.setup_consumers information. |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret to store credentials for this MySQL integration instance. |
| secret.embed | bool | `false` | If true, skip secret creation and embed the credentials directly into the configuration. |
| secret.name | string | `""` | The name of the secret to create. |
| secret.namespace | string | `""` | The namespace for the secret. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| queryAnalysis.collectors.querySamples.disableQueryRedaction | bool | `false` |  |
