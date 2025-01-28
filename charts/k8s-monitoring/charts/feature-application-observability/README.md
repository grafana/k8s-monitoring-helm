<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# feature-application-observability

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)
Gathers application data

The Application Observability feature enables the collection of application telemetry data.

## Before enabling

Before you enable this feature, you must enable one or more receivers where data will be sent from the application.

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `deployAsConfigMap` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Connectors: Grafana Cloud Host Info

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| connectors.grafanaCloudMetrics.enabled | bool | `true` | Generate host info metrics from telemetry data. These metrics are required for using Application Observability in Grafana Cloud. Note: Enabling this may incur additional costs. See [Application Observability Pricing](https://grafana.com/docs/grafana-cloud/monitor-applications/application-observability/pricing/) |

### Connectors: Span Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| connectors.spanLogs.enabled | bool | `false` | Use a span logs connector which creates logs from spans. |
| connectors.spanLogs.labels | list | `[]` | A list of keys that will be logged as labels. |
| connectors.spanLogs.process | bool | `false` | Log one line for every process. |
| connectors.spanLogs.processAttributes | list | `[]` | Additional process attributes to log. |
| connectors.spanLogs.roots | bool | `false` | Log one line for every root span of a trace. |
| connectors.spanLogs.spanAttributes | list | `[]` | Additional span attributes to log. |
| connectors.spanLogs.spans | bool | `false` | Create a log line for each span. This can lead to a large number of logs. |

### Connectors: Span Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| connectors.spanMetrics.dimensions | list | `[]` | Define dimensions to be added. Some are set internally by default: [service.name, span.name, span.kind, status.code] Example: - name: "http.status_code" - name: "http.method"   default: "GET" |
| connectors.spanMetrics.dimensionsCacheSize | int | `1000` | How many dimensions to cache |
| connectors.spanMetrics.enabled | bool | `false` | Use a span metrics connector which creates metrics from spans. |
| connectors.spanMetrics.events.enabled | bool | `false` | Capture events metrics, which track span events. |
| connectors.spanMetrics.exemplars.enabled | bool | `false` | Attach exemplars to histograms. |
| connectors.spanMetrics.exemplars.maxPerDataPoint | number | `nil` | Limits the number of exemplars that can be added to a unique dimension set. |
| connectors.spanMetrics.histogram.enabled | bool | `true` | Capture histogram metrics, derived from spans’ durations. |
| connectors.spanMetrics.histogram.explicit.buckets | list | `["2ms","4ms","6ms","8ms","10ms","50ms","100ms","200ms","400ms","800ms","1s","1400ms","2s","5s","10s","15s"]` | The histogram buckets to use. |
| connectors.spanMetrics.histogram.exponential.maxSize | int | `160` | Maximum number of buckets per positive or negative number range. |
| connectors.spanMetrics.histogram.type | string | `"explicit"` | Type of histograms to create. Must be either "explicit" or "exponential". |
| connectors.spanMetrics.histogram.unit | string | `"ms"` | The histogram unit. |
| connectors.spanMetrics.namespace | string | `"traces.span.metrics"` | The Metric namespace. |

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

### Processors: Interval

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.interval.enabled | bool | `false` | Utilize an interval processor to aggregate metrics and periodically forward the latest values to the next component in the pipeline. |
| processors.interval.interval | string | `"60s"` | The interval at which to emit aggregated metrics. |
| processors.interval.passthrough.gauge | bool | `false` | Determines whether gauge metrics should be passed through as they are or aggregated. |
| processors.interval.passthrough.summary | bool | `false` | Determines whether summary metrics should be passed through as they are or aggregated. |

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
| receivers.jaeger.includeDebugMetrics | bool | `false` | Whether to include high-cardinality debug metrics. |
| receivers.jaeger.thriftBinary | object | `{"enabled":false,"port":6832}` | Configuration for the Jaeger receiver using the Thrift binary protocol. |
| receivers.jaeger.thriftCompact | object | `{"enabled":false,"port":6831}` | Configuration for the Jaeger receiver using the Thrift compact protocol. |
| receivers.jaeger.thriftHttp | object | `{"enabled":false,"port":14268}` | Configuration for the Jaeger receiver using the Thrift HTTP protocol. |

### Receivers: OTLP

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.otlp.grpc | object | `{"enabled":false,"port":4317}` | The OTLP gRPC receiver configuration. |
| receivers.otlp.http | object | `{"enabled":false,"port":4318}` | The OTLP HTTP receiver configuration. |
| receivers.otlp.includeDebugMetrics | bool | `false` | Whether to include high-cardinality debug metrics. |

### Receivers: Zipkin

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.zipkin | object | `{"enabled":false,"includeDebugMetrics":false,"port":9411}` | The Zipkin receiver configuration. |
| receivers.zipkin.includeDebugMetrics | bool | `false` | Whether to include high-cardinality debug metrics. |

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
