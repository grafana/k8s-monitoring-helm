<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring-feature-application-observability

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)
Gathers application data

The Application Observability feature enables the collection of application telemetry data. Enabling this feature
requires enabling one or more receivers where data will be sent from the application.

## Testing

This chart contains unit tests to verify the generated configuration. A hidden value, `deployAsConfigMap`, will render
the generated configuration into a ConfigMap object. This ConfigMap is not used during regular operation, but it is
useful for showing the outcome of a given values file.

The unit tests use this to create an object with the configuration that can be asserted against. To run the tests, use
`helm test`.

Actual integration testing in a live environment should be done in the main [k8s-monitoring](../k8s-monitoring) chart.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-application-observability>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |

### Processors: Batch

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.batch.maxSize | int | `0` | The upper limit of the amount of data contained in a single batch, in bytes. When set to 0, batches can be any size. |
| processors.batch.size | int | `16384` | What batch size to use, in bytes |
| processors.batch.timeout | string | `"2s"` | How long before sending (Processors) |

### Processors: Grafana Cloud Host Info

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.grafanaCloudMetrics.enabled | bool | `true` | Generate host info metrics from telemetry data, used in Application Observability in Grafana Cloud. |

### Processors: K8s Attributes

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.k8sattributes.annotations | list | `[]` | Kubernetes annotations to extract and add to the attributes of the received telemetry data. |
| processors.k8sattributes.labels | list | `[]` | Kubernetes labels to extract and add to the attributes of the received telemetry data. |
| processors.k8sattributes.metadata | list | `["k8s.namespace.name","k8s.pod.name","k8s.deployment.name","k8s.statefulset.name","k8s.daemonset.name","k8s.cronjob.name","k8s.job.name","k8s.node.name","k8s.pod.uid","k8s.pod.start_time"]` | Kubernetes metadata to extract and add to the attributes of the received telemetry data. |

### Processors: Memory Limiter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. |
| processors.memoryLimiter.enabled | bool | `false` | Use a memory limiter. |
| processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. |

### Receivers: Jaeger

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.jaeger.grpc | object | `{"enabled":false,"port":14250}` | Configuration for the Jaeger receiver using the gRPC protocol. |
| receivers.jaeger.include_debug_metrics | bool | `false` | Whether to include high-cardinality debug metrics. |
| receivers.jaeger.thriftBinary | object | `{"enabled":false,"port":6832}` | Configuration for the Jaeger receiver using the Thrift binary protocol. |
| receivers.jaeger.thriftCompact | object | `{"enabled":false,"port":6831}` | Configuration for the Jaeger receiver using the Thrift compact protocol. |
| receivers.jaeger.thriftHttp | object | `{"enabled":false,"port":14268}` | Configuration for the Jaeger receiver using the Thrift HTTP protocol. |

### Receivers: OTLP

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.otlp.grpc | object | `{"enabled":false,"port":4317}` | The OTLP gRPC receiver configuration. |
| receivers.otlp.http | object | `{"enabled":false,"port":4318}` | The OTLP HTTP receiver configuration. |
| receivers.otlp.include_debug_metrics | bool | `false` | Whether to include high-cardinality debug metrics. |

### Receivers: Zipkin

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.zipkin | object | `{"enabled":false,"include_debug_metrics":false,"port":9411}` | The Zipkin receiver configuration. |
| receivers.zipkin.include_debug_metrics | bool | `false` | Whether to include high-cardinality debug metrics. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `true` |  |
| logs.filters | object | `{"log_record":[]}` | Apply a filter to logs received via receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.filter/)) |
| logs.transforms | object | `{"labels":["cluster","namespace","job","pod"],"log":[],"resource":[]}` | Apply a transformation to logs received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.transform/)) |
| logs.transforms.labels | list | `["cluster","namespace","job","pod"]` | The list of labels to set in the log stream. |
| logs.transforms.log | list | `[]` | Log transformation rules. |
| logs.transforms.resource | list | `[]` | Resource transformation rules. |
| metrics.enabled | bool | `true` |  |
| metrics.filters | object | `{"datapoint":[],"metric":[]}` | Apply a filter to metrics received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.filter/)) |
| metrics.transforms | object | `{"datapoint":[],"metric":[],"resource":[]}` | Apply a transformation to metrics received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.transform/)) |
| traces.enabled | bool | `true` |  |
| traces.filters | object | `{"span":[],"spanevent":[]}` | Apply a filter to traces received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.filter/)) |
| traces.transforms | object | `{"resource":[],"span":[],"spanevent":[]}` | Apply a transformation to traces received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.transform/)) |
