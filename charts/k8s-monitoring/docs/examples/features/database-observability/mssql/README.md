<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/database-observability/mssql/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: db-o11y-mssql-test

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

integrations:
  collector: alloy-singleton
  mssql:
    instances:
      - name: test-db
        exporter:
          dataSource:
            host: test-database-mssql.mssql.svc
            port: 1433
            database: testdb
            auth:
              usernameKey: mssql-username
              passwordKey: mssql-password
            params:
              encrypt: disable
        databaseObservability:
          enabled: true
        secret:
          create: false
          name: test-database-mssql
          namespace: mssql
        logs:
          enabled: true
          labelSelectors:
            app.kubernetes.io/instance: test-database

podLogsViaLoki:
  enabled: true
  collector: alloy-logs
  onlyGatherNewLogLines: false

collectors:
  alloy-singleton:
    presets: [singleton]
    alloy:
      stabilityLevel: experimental

  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
```
<!-- textlint-enable terminology -->
