# mysql

## Values

### Exporter Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| exporter.collectors | list | `["heartbeat","mysql.user"]` | The list of collectors to enable for the MySQL Exporter ([Documentation](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.mysql/#supported-collectors)). |
| exporter.dataSource | object | `{"auth":{"password":"","passwordFrom":"","passwordKey":"password","username":"","usernameFrom":"","usernameKey":"username"},"host":"","port":3306}` | The data source to use for the MySQL Exporter. |
| exporter.dataSource.auth.password | string | `""` | The password to use for the MySQL connection. |
| exporter.dataSource.auth.passwordFrom | string | `""` | Raw config for accessing the password. |
| exporter.dataSource.auth.passwordKey | string | `"password"` | The key for storing the password in the secret. |
| exporter.dataSource.auth.username | string | `""` | The username to use for the MySQL connection. |
| exporter.dataSource.auth.usernameFrom | string | `""` | Raw config for accessing the username. |
| exporter.dataSource.auth.usernameKey | string | `"username"` | The key for storing the username in the secret. |
| exporter.dataSource.host | string | `""` | The MySQL host to connect to. |
| exporter.dataSource.port | int | `3306` | The MySQL port to connect to. |
| exporter.dataSourceName | string | `""` | The data source string to use for the MySQL Exporter. |
| exporter.enabled | bool | `true` | Whether to enable the Alloy-embedded MySQL Exporter. |

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

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret to store credentials for this MySQL integration instance. |
| secret.embed | bool | `false` | If true, skip secret creation and embed the credentials directly into the configuration. |
| secret.name | string | `""` | The name of the secret to create. |
| secret.namespace | string | `""` | The namespace for the secret. |
