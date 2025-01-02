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

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fieldSelectors | list | `[]` | Discover MySQL instances based on field selectors. |
| labelSelectors | object | `{}` | Discover MySQL instances based on label selectors. Will automatically set a matcher for `app.kubernetes.io/name: <name>` unless set here. |
| namespaces | list | `[]` | The namespaces to look for MySQL instances in. Will automatically look for MySQL instances in all namespaces unless specified here |

### Logs Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `true` | Whether to enable special processing of MySQL pod logs. |

### Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.enabled | bool | `true` | Whether to enable metrics collection from MySQL Exporter. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from MySQL Exporter. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | Name for this MySQL instance. |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret to store credentials for this MySQL integration instance. |
| secret.embed | bool | `false` | If true, skip secret creation and embed the credentials directly into the configuration. |
| secret.name | string | `""` | The name of the secret to create. |
| secret.namespace | string | `""` | The namespace for the secret. |
