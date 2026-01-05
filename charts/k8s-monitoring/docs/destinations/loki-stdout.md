# loki-stdout

<!-- textlint-disable terminology -->
## Values

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logProcessingRules | string | `""` | Rule blocks to be evaluated before printing the log messages to the standard output. See ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.relabel/#rule)) for more information. |
| logProcessingStages | string | `""` | Stage blocks to be evaluated before printing the log messages to the standard output. See ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#blocks)) for more information. |
| name | string | `""` | The name for this Loki Stdout destination. |
<!-- textlint-enable terminology -->
