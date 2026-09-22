<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# PostgreSQL error logs from files

Mount an existing PostgreSQL log volume read-only into a singleton collector. The volume must support access from
the database and the collector, and the collector needs permission to read its files.

Create the `postgresql-monitoring` Secret in the `monitoring` namespace with `username` and `password` keys.
Configure PostgreSQL with `log_line_prefix = '%m:%r:%u@%d:[%p]:%l:%e:%s:%v:%x:%c:%q%a:'` and
`log_min_error_statement = ERROR`. Use a CGO-enabled Alloy 1.19 or newer build.

See the [PostgreSQL integration](../../../../../charts/feature-integrations/docs/integrations/postgresql.md) for
source settings and runtime prerequisites.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: postgresql-error-logs

destinations:
  metrics:
    type: prometheus
    url: http://prometheus.monitoring.svc:9090/api/v1/write
  logs:
    type: loki
    url: http://loki.monitoring.svc:3100/loki/api/v1/push

integrations:
  collector: alloy-singleton
  postgresql:
    instances:
      - name: example-db
        exporter:
          dataSource:
            host: example-db.postgresql.svc
            database: postgres
            auth:
              usernameKey: username
              passwordKey: password
        secret:
          create: false
          name: postgresql-monitoring
          namespace: monitoring
        logs:
          enabled: false
        databaseObservability:
          enabled: true
          collectors:
            logs:
              enabled: true
          logSource:
            type: file
            file:
              paths: [/var/log/postgresql/*.log]
              tailFromEnd: true

collectors:
  alloy-singleton:
    presets: [singleton]
    alloy:
      mounts:
        extra:
          - name: postgresql-logs
            mountPath: /var/log/postgresql
            readOnly: true
    controller:
      volumes:
        extra:
          - name: postgresql-logs
            persistentVolumeClaim:
              claimName: postgresql-logs
```
<!-- textlint-enable terminology -->
