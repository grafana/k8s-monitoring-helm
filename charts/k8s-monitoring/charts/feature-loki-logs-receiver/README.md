<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Loki Logs Receiver

This feature provides a receiver for logs delivered over the Loki API, where processing rules can be defined before
delivering to the logs destination. It uses the
[`loki.source.api`](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.source.api/) component, which
exposes an HTTP server that accepts logs pushed to the Loki-compatible push API.

## Usage

```yaml
lokiLogsReceiver:
  enabled: true
  ...
```

([values](#values))

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `testing.enabled` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

<!-- textlint-disable terminology -->
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
| TylerHelmuth | <tyler.helmuth@grafana.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-loki-logs-receiver>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.namespaceOverride | string | `""` | Override the namespace for namespaced resources created by this chart. |

### Listener Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| labels | object | `{}` | Labels to add to all received log entries. |
| port | int | `3500` | Port number on which the server listens for new connections. |
| useIncomingTimestamp | bool | `false` | Whether to use the timestamp from the incoming request as the log timestamp. When disabled, the time the log was received is used. |

### Log Processing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logProcessingRules | string | `""` | Rule blocks to be added to the loki.relabel component for received logs. These relabeling rules are applied to logs received by this feature. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.relabel/#rule)) |
