# mysql

## Values

### Database Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| databaseObservability.allowUpdatePerformanceSchemaSettings | bool | `false` | Whether to allow updates to performance_schema settings in any collector. |
| databaseObservability.enabled | bool | `false` | Whether to gather table, schema, and query information from the database. Requires exporter to be enabled. |

### Database Observability - Collectors

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| databaseObservability.collectors.explainPlans.collectInterval | string | `"1m"` | How frequently to collect explain plans information from the database. |
| databaseObservability.collectors.explainPlans.enabled | bool | `false` | Enable collection of explain plans information. |
| databaseObservability.collectors.explainPlans.excludeSchemas | list | `[]` | List of schemas to exclude from explain plan collection. |
| databaseObservability.collectors.explainPlans.initialLookback | string | `"24h"` | How far back to look for explain plan queries on the first collection interval. |
| databaseObservability.collectors.explainPlans.perCollectRatio | float | `1` | Ratio of explain plan queries to collect per collect interval. |
| databaseObservability.collectors.locks.collectInterval | string | `"1m"` | How frequently to collect lock information from the database. |
| databaseObservability.collectors.locks.enabled | bool | `false` | Enable collection of lock information. |
| databaseObservability.collectors.locks.threshold | string | `"1s"` | Threshold for locks to be considered slow. Locks that exceed this duration are logged. |
| databaseObservability.collectors.queryDetails.collectInterval | string | `"1m"` | How frequently to collect query information from the database. |
| databaseObservability.collectors.queryDetails.enabled | bool | `true` | Enable collection of query information. |
| databaseObservability.collectors.querySamples.autoEnableSetupConsumers | bool | `false` | Whether to enable some specific performance_schema.setup_consumers settings. |
| databaseObservability.collectors.querySamples.collectInterval | string | `"1m"` | How frequently to collect query samples from the database. |
| databaseObservability.collectors.querySamples.disableQueryRedaction | bool | `false` | Collect unredacted SQL query text including parameters. |
| databaseObservability.collectors.querySamples.enabled | bool | `true` | Enable collection of query samples. |
| databaseObservability.collectors.querySamples.setupConsumersCheckInterval | string | `"1h"` | How frequently to check if setup_consumers are correctly enabled. |
| databaseObservability.collectors.schemaDetails.cacheEnabled | bool | `false` | Whether to enable caching of table definitions. |
| databaseObservability.collectors.schemaDetails.cacheSize | int | `256` | Table definitions cache size. |
| databaseObservability.collectors.schemaDetails.cacheTTL | string | `"10m"` | Table definitions cache TTL. |
| databaseObservability.collectors.schemaDetails.collectInterval | string | `"1m"` | How frequently to collect schemas and tables from information_schema. |
| databaseObservability.collectors.schemaDetails.enabled | bool | `true` | Enable collection of schemas and tables from information_schema. |
| databaseObservability.collectors.setupConsumers.collectInterval | string | `"1m"` | How frequently to collect performance_schema.setup_consumers information from the database. |
| databaseObservability.collectors.setupConsumers.enabled | bool | `true` | Enable collection of performance_schema.setup_consumers information. |

### Exporter Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| exporter.collectors | object | `{"heartbeat":{"database":"","enabled":true,"table":""},"mysqlUser":{"enabled":true,"privileges":false},"perfSchemaEventsStatements":{"enabled":false}}` | The list of collectors to enable for the MySQL Exporter ([Documentation](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.mysql/#supported-collectors)). This used to be a list of collector names. This format is still supported, but the new format will allow for customization. collectors: ["heartbeat", "mysql.user"] |
| exporter.dataSource.allowFallbackToPlaintext | bool | `false` | The TLS setting to use. Options are none, "true", "false", "skip-verify", "preferred". See the [driver documentation](https://github.com/go-sql-driver/mysql#tls) for details. |
| exporter.dataSource.auth.password | string | `""` | The password to use for the MySQL connection. |
| exporter.dataSource.auth.passwordFrom | string | `""` | Raw config for accessing the password. |
| exporter.dataSource.auth.passwordKey | string | `"password"` | The key for storing the password in the secret. |
| exporter.dataSource.auth.username | string | `""` | The username to use for the MySQL connection. |
| exporter.dataSource.auth.usernameFrom | string | `""` | Raw config for accessing the username. |
| exporter.dataSource.auth.usernameKey | string | `"username"` | The key for storing the username in the secret. |
| exporter.dataSource.host | string | `""` | The MySQL host to connect to. |
| exporter.dataSource.port | int | `3306` | The MySQL port to connect to. |
| exporter.dataSource.protocol | string | `""` | The MySQL protocol type. |
| exporter.dataSource.tls | string | `""` | The TLS setting to use. Options are none, "true", "false", "skip-verify", "preferred". See the [driver documentation](https://github.com/go-sql-driver/mysql#tls) for details. |
| exporter.dataSourceName | string | `""` | The data source string to use for the MySQL Exporter. |

### Exporter Collectors

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| exporter.collectors.heartbeat.database | string | `heartbeat` | Database to collect heartbeat data from. |
| exporter.collectors.heartbeat.enabled | bool | `true` | Enable heartbeat collector. |
| exporter.collectors.heartbeat.table | string | `heartbeat` | Table to collect heartbeat data from. |
| exporter.collectors.mysqlUser.enabled | bool | `true` | Enable mysql.user collector. |
| exporter.collectors.mysqlUser.privileges | bool | `false` | Enable collecting user privileges from mysql.user. |
| exporter.collectors.perfSchemaEventsStatements.enabled | bool | `false` | Enable perf_schema.eventsstatements collector. |

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
| logs.labelSelectors | object | `{}` | Discover MySQL instances based on label selectors. At least one is required. |
| logs.namespaces | list | `[]` | The namespaces to look for MySQL instances in. Will automatically look for MySQL instances in all namespaces unless specified here |

### Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.enabled | bool | `true` | Whether to enable metrics collection from MySQL Exporter. |

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

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret to store credentials for this MySQL integration instance. |
| secret.embed | bool | `false` | If true, skip secret creation and embed the credentials directly into the configuration. |
| secret.name | string | `""` | The name of the secret to create. |
| secret.namespace | string | `""` | The namespace for the secret. |
