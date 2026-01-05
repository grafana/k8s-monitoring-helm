<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Log Metrics

This example shows how to generate metrics based on the log data. It utilizes a `stage.metric` processor within the
[loki.process](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#stagemetrics) component
to generate metrics captured from the Pod logs. This is an example metric, but other metrics can be added, or more
complex stages can be utilized to filter and match on certain log lines and build metrics from them.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: log-metrics-example

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

podLogs:
  enabled: true

  extraLogProcessingStages: |-
    stage.metrics {
      metric.counter {
        name        = "log_lines_total"
        description = "total number of log lines"
        prefix      = "my_custom_tracking_"

        match_all         = true
        action            = "inc"
        max_idle_duration = "24h"
      }
    }

integrations:
  alloy:
    instances:
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: [alloy-metrics, alloy-logs]
        metrics:
          tuning:
            includeMetrics: [my_custom_tracking_.*]

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
