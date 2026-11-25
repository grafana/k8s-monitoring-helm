# MSSQL Integration

This integration captures metrics and logs from a Microsoft SQL Server instance. This deploys the
[MSSQL Exporter Alloy component](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.mssql/)
which connects to the database to generate metrics.

This integration is also compatible with [Grafana Database Observability](https://grafana.com/docs/grafana-cloud/monitor-applications/database-observability/)
using the experimental
[`database_observability.sql_server` component](https://grafana.com/docs/alloy/latest/reference/components/database_observability/database_observability.sql_server/).
Enabling Database Observability requires an Alloy collector running with `stabilityLevel: experimental` and
[Query Store](https://learn.microsoft.com/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store)
enabled on the target database.

## Enabling

To enable this integration, create an instance:

```yaml
integrations:
  mssql:
    instances:
      - name: test-db
        exporter:
          dataSource:
            host: test-db.default.svc
            port: 1433
            auth:
              username: sa
              password: mssql-password
        logs:
          enabled: true
          labelSelectors:
            app: mssql-test-db
```

To enable with Database Observability, enable the `databaseObservability` flag:

```yaml
integrations:
  mssql:
    instances:
      - name: test-db
        databaseObservability:
          enabled: true
        exporter:
          dataSource:
            host: test-db.default.svc
            port: 1433
            auth:
              username: sa
              password: mssql-password
        logs:
          enabled: true
          labelSelectors:
            app.kubernetes.io/instance: test-mssql-db
```

To enable with Database Observability and a cloud provider, specify the `cloudProvider` field:

```yaml
integrations:
  mssql:
    instances:
      - name: test-db
        databaseObservability:
          enabled: true
          cloudProvider:
            aws:
              arn: "arn:aws:rds:us-east-1:123456789012:db:my-mssql-instance"
        exporter:
          dataSource:
            host: test-db.default.svc
            port: 1433
            auth:
              username: sa
              password: mssql-password
        logs:
          enabled: true
          labelSelectors:
            app.kubernetes.io/instance: test-mssql-db
```

## Values

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| collector | string | `""` | The collector to assign this instance to. When empty, the feature-level `integrations.collector` is used. |
| jobLabel | string | `"integration/mssql"` | The value of the job label for scraped metrics and logs |
| name | string | `""` | Name for this MSSQL instance. |

### Database Observability - Cloud Provider

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| databaseObservability.cloudProvider.aws.arn | string | `""` | ARN of the AWS RDS instance. |
| databaseObservability.cloudProvider.azure.resourceGroup | string | `""` | The Resource Group that holds the database resource. |
| databaseObservability.cloudProvider.azure.serverName | string | `""` | The database server name. |
| databaseObservability.cloudProvider.azure.subscriptionId | string | `""` | The Subscription ID for your Azure account. |
| databaseObservability.cloudProvider.gcp.connectionName | string | `""` | The Cloud SQL instance connection name in the format `project:region:instance`. |

### Database Observability - Collectors

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| databaseObservability.collectors.explainPlans.collectInterval | string | `"1m"` | How frequently to check for changed execution plans. |
| databaseObservability.collectors.explainPlans.enabled | bool | `true` | Enable collection of explain plans information. |
| databaseObservability.collectors.queryDetails.collectInterval | string | `"1m"` | How frequently to collect query information from the database. |
| databaseObservability.collectors.queryDetails.enabled | bool | `true` | Enable collection of query information. |
| databaseObservability.collectors.queryMetrics.collectInterval | string | `"1m"` | How frequently to collect query metrics from the database. |
| databaseObservability.collectors.queryMetrics.enabled | bool | `true` | Enable collection of query metrics from Query Store. |
| databaseObservability.collectors.queryMetrics.statementsLimit | number | `50` | Maximum number of queries to track, ranked by recent duration. |
| databaseObservability.collectors.queryMetrics.statementsLookback | string | `"1h"` | Only queries executed within this window are eligible for tracking. |
| databaseObservability.collectors.querySamples.collectInterval | string | `"10s"` | How frequently to collect query samples from the database. |
| databaseObservability.collectors.querySamples.disableQueryRedaction | bool | `false` | Collect unredacted SQL query text including parameters. |
| databaseObservability.collectors.querySamples.enabled | bool | `true` | Enable collection of query samples. |
| databaseObservability.collectors.schemaDetails.collectInterval | string | `"1m"` | How frequently to collect schemas and tables from information_schema. |
| databaseObservability.collectors.schemaDetails.enabled | bool | `true` | Enable collection of schemas and tables from information_schema. |

### Database Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| databaseObservability.enabled | bool | `false` | Whether to gather table, schema, and query information from the database. Requires exporter to be enabled. |
| databaseObservability.excludeCurrentUser | bool | `true` | Exclude query samples from sessions opened with the login that Alloy uses. |
| databaseObservability.excludeDatabases | list | `[]` | A list of databases to exclude from monitoring, in addition to always-excluded system databases. |
| databaseObservability.excludeSchemas | list | `[]` | A list of schemas to exclude from monitoring, in addition to always-excluded system schemas. |
| databaseObservability.excludeUsers | list | `[]` | A list of original SQL Server login names to exclude from query samples. |
| databaseObservability.labels | object | `{}` | Additional static labels to add to both metrics and logs produced by Database Observability for this instance. Keys are label names, values are label values. The reserved labels `job`, `instance`, and `dsn` cannot be overridden. |
| databaseObservability.queryTimeout | string | `10s` | Timeout for each SQL statement used by Database Observability collectors. |

### Exporter Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| exporter.connectionName | string | `""` | A name for the connection. When set, the exporter emits `up` and `scrape_duration_seconds` metrics for the connection. |
| exporter.dataSource.auth.password | string | `""` | The password to use for the MSSQL connection. |
| exporter.dataSource.auth.passwordFrom | string | `""` | Raw Alloy config for accessing the password. |
| exporter.dataSource.auth.passwordKey | string | `"password"` | The key for storing the password in the secret. |
| exporter.dataSource.auth.username | string | `""` | The username to use for the MSSQL connection. |
| exporter.dataSource.auth.usernameFrom | string | `""` | Raw Alloy config for accessing the username. |
| exporter.dataSource.auth.usernameKey | string | `"username"` | The key for storing the username in the secret. |
| exporter.dataSource.database | string | `""` | The MSSQL database to connect to. When empty, the server default database is used. |
| exporter.dataSource.host | string | `""` | The MSSQL host to connect to. |
| exporter.dataSource.params.appName | string | `""` | Application name reported to SQL Server. |
| exporter.dataSource.params.authenticator | string | `""` | Authentication mode (for example `ntlm` or `winsspi`). |
| exporter.dataSource.params.encrypt | string | `""` | Encrypt the connection (`true`/`false`/`disable`). |
| exporter.dataSource.params.extra | object | `{}` | Additional connection string query parameters as key/value pairs. |
| exporter.dataSource.params.hostNameInCertificate | string | `""` | Expected host name in the server certificate. |
| exporter.dataSource.params.trustServerCertificate | string | `""` | Trust the server certificate (`true`/`false`). |
| exporter.dataSource.port | int | `1433` | The MSSQL port to connect to. |
| exporter.dataSourceName | string | `""` | The connection string to use for the MSSQL Exporter (`sqlserver://` URL). Takes precedence over `dataSource` when set. |
| exporter.dataSourceNameFrom | string | `""` | Raw Alloy config for the exporter `connection_string` argument. Use this to get the value from other Alloy components. |
| exporter.maxConnectionLifetime | string | `""` | Maximum lifetime of a connection. `0s` keeps connections forever. |
| exporter.maxIdleConnections | number | `3` | Maximum number of idle connections in the connection pool. |
| exporter.maxOpenConnections | number | `3` | Maximum number of open connections in the connection pool. |
| exporter.queryConfig | string | `""` | Collector configuration YAML that maps MSSQL queries to custom Prometheus metrics. |
| exporter.queryConfigFrom | string | `""` | Raw Alloy config for the exporter `query_config` argument (for example from another component export). |
| exporter.timeout | string | `10s` | Query timeout for each scrape. |

### Logs Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `true` | Whether to enable special processing of MSSQL pod logs. |

### Discovery Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.labelSelectors | object | `{}` | Discover MSSQL instances based on label selectors. At least one is required. |
| logs.namespaces | list | `[]` | The namespaces to look for MSSQL instances in. Will automatically look for MSSQL instances in all namespaces unless specified here |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.cacheTTL | string | `""` | Sets the cache_ttl for the prometheus.relabel component, which switches its relabeling cache to TTL mode. Mutually exclusive with `maxCacheSize`. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)). Overrides `global.cacheTTL`. |
| metrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for MSSQL metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| metrics.maxCacheSize | number | `100000` | Sets the max_cache_size for prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)). Overrides `global.maxCacheSize`. |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Metrics Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.enabled | bool | `true` | Whether to enable metrics collection from MSSQL Exporter. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from MSSQL Exporter. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from MSSQL Exporter. |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret to store credentials for this MSSQL integration instance. |
| secret.embed | bool | `false` | If true, skip secret creation and embed the credentials directly into the configuration. |
| secret.name | string | `""` | The name of the secret to create. |
| secret.namespace | string | `""` | The namespace for the secret. |
