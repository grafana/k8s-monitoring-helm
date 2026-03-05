<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Integration: MySQL

This example demonstrates how to gather metrics and logs from [MySQL](https://www.mysql.com/).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: mysql-integration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

integrations:
  mysql:
    instances:
      - name: dev-db
        exporter:
          dataSourceName: "root:password@database.dev.svc:3306/"
        logs:
          enabled: false

      - name: staging-db
        exporter:
          dataSource:
            host: database.staging.svc
            protocol: tcp
            port: 3306
            auth:
              usernameKey: mysql-username
              passwordKey: mysql-root-password
        secret:
          create: false
          name: mysql-creds
          namespace: staging
        logs:
          enabled: false

      - name: prod-db
        exporter:
          dataSource:
            host: database.prod.svc
            auth:
              username: db-admin
              password: db-password
        logs:
          labelSelectors:
            app.kubernetes.io/instance: prod-db

podLogs:
  enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
