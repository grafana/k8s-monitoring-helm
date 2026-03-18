<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Integration: PostgreSQL

This example demonstrates how to gather metrics and logs from [PostgreSQL](https://www.postgresql.org/).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: postgresql-integration-test-cluster

destinations:
  localPrometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
  localLoki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

integrations:
  collector: alloy-metrics
  postgresql:
    instances:
      - name: test-database
        exporter:
          dataSource:
            host: test-database-pg-db-primary.postgresql.svc
            auth:
              usernameKey: user
              passwordKey: password
        secret:
          create: false
          name: test-database-pg-db-pguser-test-database-pg-db
          namespace: postgresql
        logs:
          enabled: true
          labelSelectors:
            app.kubernetes.io/instance: test-database-pg-db

podLogs:
  enabled: true
  collector: alloy-logs

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]

  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
```
<!-- textlint-enable terminology -->
