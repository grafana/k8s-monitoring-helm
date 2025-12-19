<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/database-observability/postgresql/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: db-o11y-postgresql-test-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
  - name: localLoki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

integrations:
  postgresql:
    instances:
      - name: test-database
        jobLabel: integrations/db-o11y
        exporter:
          dataSource:
            host: test-database-pg-db-primary.postgresql.svc
            auth:
              usernameKey: user
              passwordKey: password
        databaseObservability:
          enabled: true
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

alloy-metrics:
  enabled: true
  alloy:
    stabilityLevel: experimental

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
