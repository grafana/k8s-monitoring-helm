# PostgreSQL Integration

This integration captures the metrics and logs to collect stats from a PostgreSQL server. This deploys the
[PostgreSQL Exporter Alloy component](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.postgres/)
which connects to the database to generate metrics.

This integration is also compatible with [Grafana Database Observability](https://grafana.com/docs/grafana-cloud/monitor-applications/database-observability/).

## Enabling

To enable this integration, create an instance :

```yaml
integrations:
  postgresql:
    instances:
      - name: test-database
        exporter:
          dataSource:
            host: test-database-pg-db-primary.postgresql.svc
            auth:
              username: pg-admin
              password: pg-admin-password
        logs:
          enabled: true
          labelSelectors:
            app.kubernetes.io/instance: test-database-pg-db
```

To enable with Database Observability, enable the `databaseObservability` flag:

```yaml
integrations:
  mysql:
    instances:
      - name: test-database
        jobLabel: integrations/db-o11y
        databaseObservability:
          enabled: true
        exporter:
          dataSource:
            host: test-database-pg-db-primary.postgresql.svc
            auth:
              username: pg-admin
              password: pg-admin-password
        logs:
          enabled: true
          labelSelectors:
            app.kubernetes.io/instance: test-database-pg-db
```

## Values

### Database Observability - Collectors

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| databaseObservability.collectors.explainPlans.collectInterval | string | `"1m"` | How frequently to collect explain plans information from the database. |
| databaseObservability.collectors.explainPlans.enabled | bool | `true` | Enable collection of explain plans information. |
| databaseObservability.collectors.explainPlans.excludeSchemas | list | `[]` | List of schemas to exclude from explain plan collection. |
| databaseObservability.collectors.explainPlans.perCollectRatio | float | `1` | Ratio of explain plan queries to collect per collect interval. |
| databaseObservability.collectors.queryDetails.collectInterval | string | `"1m"` | How frequently to collect query information from the database. |
| databaseObservability.collectors.queryDetails.enabled | bool | `true` | Enable collection of query information. |
| databaseObservability.collectors.querySamples.collectInterval | string | `"1m"` | How frequently to collect query samples from the database. |
| databaseObservability.collectors.querySamples.disableQueryRedaction | bool | `false` | Collect unredacted SQL query text including parameters. |
| databaseObservability.collectors.querySamples.enabled | bool | `true` | Enable collection of query samples. |
| databaseObservability.collectors.schemaDetails.cacheEnabled | bool | `true` | Whether to enable caching of table definitions. |
| databaseObservability.collectors.schemaDetails.cacheSize | int | `256` | Table definitions cache size. |
| databaseObservability.collectors.schemaDetails.cacheTTL | string | `"10m"` | Table definitions cache TTL. |
| databaseObservability.collectors.schemaDetails.collectInterval | string | `"1m"` | How frequently to collect schemas and tables from information_schema. |
| databaseObservability.collectors.schemaDetails.enabled | bool | `true` | Enable collection of schemas and tables from information_schema. |

### Database Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| databaseObservability.enabled | bool | `false` | Whether to gather table, schema, and query information from the database. Requires exporter to be enabled. |

### Exporter Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| exporter.autoDiscovery.databaseAllowList | list | `[]` | List of databases to filter out, meaning all other databases will be scraped. |
| exporter.autoDiscovery.databaseDenyList | list | `[]` | Whether to automatically discover other databases. |
| exporter.autoDiscovery.enabled | bool | `false` | Whether to automatically discover other databases. |
| exporter.collectors | object | `{"buffercacheSummary":{"enabled":false},"database":{"enabled":true},"databaseWraparound":{"enabled":false},"locks":{"enabled":true},"longRunningTransactions":{"enabled":false},"postmaster":{"enabled":false},"processIdle":{"enabled":false},"replication":{"enabled":true},"replicationSlot":{"enabled":true},"statActivityAutovacuum":{"enabled":false},"statBGWriter":{"enabled":true},"statCheckpointer":{"enabled":false},"statDatabase":{"enabled":true},"statProgressVacuum":{"enabled":true},"statStatements":{"enabled":false,"includeQuery":false,"queryLength":null},"statUserTables":{"enabled":true},"statWALReceiver":{"enabled":false},"statioUserIndexes":{"enabled":false},"statioUserTables":{"enabled":true},"wal":{"enabled":true},"xlogLocation":{"enabled":false}}` | The list of collectors to enable for the PostgreSQL Exporter ([Documentation](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.PostgreSQL/#supported-collectors)). This used to be a list of collector names. This format is still supported, but the new format will allow for customization. collectors: ["heartbeat", "PostgreSQL.user"] |
| exporter.customQueriesConfigPath | string | `""` | Path to YAML file containing custom queries to expose as metrics. |
| exporter.dataSource.auth.password | string | `""` | The password to use for the PostgreSQL connection. |
| exporter.dataSource.auth.passwordFrom | string | `""` | Raw config for accessing the password. |
| exporter.dataSource.auth.passwordKey | string | `"password"` | The key for storing the password in the secret. |
| exporter.dataSource.auth.username | string | `""` | The username to use for the PostgreSQL connection. |
| exporter.dataSource.auth.usernameFrom | string | `""` | Raw config for accessing the username. |
| exporter.dataSource.auth.usernameKey | string | `"username"` | The key for storing the username in the secret. |
| exporter.dataSource.database | string | `""` | The PostgreSQL database to access. |
| exporter.dataSource.host | string | `""` | The PostgreSQL host to connect to. |
| exporter.dataSource.port | int | `5432` | The PostgreSQL port to connect to. |
| exporter.dataSource.protocol | string | `"postgresql"` | The PostgreSQL protocol type. |
| exporter.dataSource.sslmode | string | `""` | The SSL mode setting to use. Options are none, "verify-full", "verify-ca", "require", "prefer", "allow", and "disable". See the [documentation](https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION) for details. |
| exporter.dataSourceName | string | `""` | The data source string to use for the PostgreSQL Exporter. |
| exporter.dataSourceNameFrom | string | `""` | The raw access for the data source string to use for the PostgreSQL Exporter. Use this to get the data source from other Alloy components. |
| exporter.disableDefaultMetrics | bool | `false` | When true, only exposes metrics supplied from `customQueriesConfigPath`. |
| exporter.disableSettingsMetrics | bool | `false` | Disables collection of metrics from pg_settings. |

### Exporter Collectors

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| exporter.collectors.buffercacheSummary.enabled | bool | `false` | Enable the buffercache_summary collector. |
| exporter.collectors.database.enabled | bool | `true` | Enable the database collector. |
| exporter.collectors.databaseWraparound.enabled | bool | `false` | Enable the database_wraparound collector. |
| exporter.collectors.locks.enabled | bool | `true` | Enable the locks collector. |
| exporter.collectors.longRunningTransactions.enabled | bool | `false` | Enable the long_running_transactions collector. |
| exporter.collectors.postmaster.enabled | bool | `false` | Enable the postmaster collector. |
| exporter.collectors.processIdle.enabled | bool | `false` | Enable the process_idle collector. |
| exporter.collectors.replication.enabled | bool | `true` | Enable the replication collector. |
| exporter.collectors.replicationSlot.enabled | bool | `true` | Enable the replication_slot collector. |
| exporter.collectors.statActivityAutovacuum.enabled | bool | `false` | Enable the stat_activity_autovacuum collector. |
| exporter.collectors.statBGWriter.enabled | bool | `true` | Enable the stat_bgwriter collector. |
| exporter.collectors.statCheckpointer.enabled | bool | `false` | Enable the stat_checkpointer collector. |
| exporter.collectors.statDatabase.enabled | bool | `true` | Enable the stat_database collector. |
| exporter.collectors.statProgressVacuum.enabled | bool | `true` | Enable the stat_progress_vacuum collector. |
| exporter.collectors.statStatements.enabled | bool | `false` | Enable the stat_statements collector. |
| exporter.collectors.statStatements.includeQuery | bool | `false` | Enable the selection of query ID and SQL statement. |
| exporter.collectors.statStatements.queryLength | string | 120 | Maximum length of the statement query text. |
| exporter.collectors.statUserTables.enabled | bool | `true` | Enable the stat_user_tables collector. |
| exporter.collectors.statWALReceiver.enabled | bool | `false` | Enable the stat_wal_receiver collector. |
| exporter.collectors.statioUserIndexes.enabled | bool | `false` | Enable the statio_user_indexes collector. |
| exporter.collectors.statioUserTables.enabled | bool | `true` | Enable the statio_user_tables collector. |
| exporter.collectors.wal.enabled | bool | `true` | Enable the wal collector. |
| exporter.collectors.xlogLocation.enabled | bool | `false` | Enable the xlog_location collector. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobLabel | string | `"integration/postgresql"` | The value of the job label for scraped metrics and logs |
| name | string | `""` | Name for this PostgreSQL instance. |

### Logs Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `true` | Whether to enable special processing of PostgreSQL pod logs. |

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.labelSelectors | object | `{}` | Discover PostgreSQL instances based on label selectors. At least one is required. |
| logs.namespaces | list | `[]` | The namespaces to look for PostgreSQL instances in. Will automatically look for PostgreSQL instances in all namespaces unless specified here |

### Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.enabled | bool | `true` | Whether to enable metrics collection from PostgreSQL Exporter. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for PostgreSQL metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from PostgreSQL Exporter. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from PostgreSQL Exporter. |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret to store credentials for this PostgreSQL integration instance. |
| secret.embed | bool | `false` | If true, skip secret creation and embed the credentials directly into the configuration. |
| secret.name | string | `""` | The name of the secret to create. |
| secret.namespace | string | `""` | The namespace for the secret. |
