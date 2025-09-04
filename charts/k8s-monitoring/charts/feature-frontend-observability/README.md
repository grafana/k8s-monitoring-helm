<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Frontend Observability

The Frontend Observability feature enables the collection of application telemetry data from faro instrumented frontend applications.

## Usage

```yaml
frontendApplication:
  enabled: true
    ...
```

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `deployAsConfigMap` will render
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
| rlankfo | <robert.lankford@grafana.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

<!--alex disable host-hostess-->
## Values

### Processors: Batch

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.batch.maxSize | int | `0` | Maximum number of spans, metric data points, or log records to send in a single batch. This number must be greater than or equal to the `size` setting. If set to 0, the batch processor will not enforce a maximum size. |
| processors.batch.size | int | `8192` | Number of spans, metric data points, or log records after which a batch will be sent regardless of the timeout. This setting acts as a trigger and does not affect the size of the batch. If you need to enforce batch size limit, use `maxSize`. |
| processors.batch.timeout | string | `"2s"` | How long before sending (Processors) |

### Processors: Memory Limiter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. |
| processors.memoryLimiter.enabled | bool | `false` | Use a memory limiter. |
| processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.faro | string | `nil` |  |
<!--alex enable host-hostess-->
