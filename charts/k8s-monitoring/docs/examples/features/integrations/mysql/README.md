<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# MySQL Integration

This example shows how to load two MySQL integration instances, which utilize Alloy's [prometheus.exporter.mysql](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.mysql/) component
to scrape metrics from the MySQL database. It also modifies the Pod Logs feature to add special log handling for MySQL
pods. The username and password for the `prod-db` example are stored in a Kubernetes secret.

## Values

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
      - name: staging-db
        exporter:
          dataSourceName: "root:password@database.staging.svc:3306/"
        logs:
          labelSelectors:
            app.kubernetes.io/instance: staging-db

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
