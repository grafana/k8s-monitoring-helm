<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Prometheus Metrics Receiver

This feature provides a receiver for Prometheus metrics where processing rules can be defined before delivering to the
metrics destination.

## Usage

```yaml
prometheusMetricsReceiver:
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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-prometheus-metrics-receiver>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.namespaceOverride | string | `""` | Override the namespace for namespaced resources created by this chart. |

### Metric Processing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for received metrics. These relabeling rules are applied to metrics received by this feature. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule)) |

### Listener Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| port | int | `9090` | Port number on which the server listens for new connections. |
