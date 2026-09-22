<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# PostgreSQL error logs from CloudWatch

Export the RDS instance's PostgreSQL logs to CloudWatch. Configure the existing `postgresql-cloudwatch` ServiceAccount
with IRSA or Pod Identity and grant its AWS role permission to read the log group. Create a writable
`postgresql-cloudwatch-checkpoints` PersistentVolumeClaim for Alloy's receiver checkpoints.

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
            host: example-db.example.eu-west-1.rds.amazonaws.com
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
          healthCheck:
            collectInterval: 30m
          collectors:
            querySamples:
              enablePreClassifiedWaitEvents: true
            logs:
              enabled: true
          logSource:
            type: cloudwatch
            cloudwatch:
              region: eu-west-1
              groupName: /aws/rds/instance/example-db/postgresql
              pollInterval: 1m

collectors:
  alloy-singleton:
    presets: [singleton]
    alloy:
      stabilityLevel: experimental
      storagePath: /var/lib/alloy
      mounts:
        extra:
          - name: checkpoints
            mountPath: /var/lib/alloy
    controller:
      volumes:
        extra:
          - name: checkpoints
            persistentVolumeClaim:
              claimName: postgresql-cloudwatch-checkpoints
    serviceAccount:
      create: false
      name: postgresql-cloudwatch
```
<!-- textlint-enable terminology -->
