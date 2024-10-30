<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/integrations/mysql/values.yaml

## Values

```yaml
---
cluster:
  name: mysql-integration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

integrations:
  mysql:
    instances:
      - name: test-db
        exporter:
          dataSource:
            host: database.test.svc
      - name: staging-db
        exporter:
          dataSourceName: "root:password@database.staging.svc:3306/"
      - name: prod-db
        exporter:
          dataSource:
            host: database.prod.svc
            auth:
              username: db-admin
              password: db-password

alloy-metrics:
  enabled: true
```
