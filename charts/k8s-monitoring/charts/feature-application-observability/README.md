<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Application Observability

The Application Observability feature enables the collection of application telemetry data.

## Before enabling

Before you enable this feature, you must [enable one or more receivers](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/Collectors.md) where data will be sent from the application.

## Usage

```yaml
applicationObservability:
  enabled: true
  receivers:
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
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

<!--alex disable host-hostess-->
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
| connectors.spanMetrics.aggregationCardinalityLimit | int | `1000` | How many unique combinations of dimensions that will be tracked for metrics aggregation |
| connectors.spanMetrics.dimensions | list | `[]` | Define dimensions to be added. Some are set internally by default: [service.name, span.name, span.kind, status.code] Example: - name: "http.status_code" - name: "http.method"   default: "GET" |
| connectors.spanMetrics.dimensionsCacheSize | int | `1000` | How many dimensions to cache. DEPRECATED, please use aggregationCardinalityLimit instead. |
| connectors.spanMetrics.enabled | bool | `false` | Use a span metrics connector which creates metrics from spans. |
| connectors.spanMetrics.events.enabled | bool | `false` | Capture events metrics, which track span events. |
| connectors.spanMetrics.excludeDimensions | list | `[]` | List of dimensions to be excluded from the default set of dimensions. |
| connectors.spanMetrics.exemplars.enabled | bool | `false` | Attach exemplars to histograms. |
| connectors.spanMetrics.exemplars.maxPerDataPoint | number | `nil` | Limits the number of exemplars that can be added to a unique dimension set. |
| connectors.spanMetrics.histogram.enabled | bool | `true` | Capture histogram metrics, derived from spans’ durations. |
| connectors.spanMetrics.histogram.explicit.buckets | list | `["2ms","4ms","6ms","8ms","10ms","50ms","100ms","200ms","400ms","800ms","1s","1400ms","2s","5s","10s","15s"]` | The histogram buckets to use. |
| connectors.spanMetrics.histogram.exponential.maxSize | int | `160` | Maximum number of buckets per positive or negative number range. |
| connectors.spanMetrics.histogram.type | string | `"explicit"` | Type of histograms to create. Must be either "explicit" or "exponential". |
| connectors.spanMetrics.histogram.unit | string | `"s"` | The histogram unit. |
| connectors.spanMetrics.namespace | string | `"traces.span.metrics"` | The Metric namespace. |
| connectors.spanMetrics.skipBeyla | bool | `true` | Skip Beyla traces when `span.metrics.skip` resource attribute is present. |
| connectors.spanMetrics.skipInternal | bool | `true` | Skip span if span kind is internal. |
| connectors.spanMetrics.transforms | object | `{"datapoint":[],"metric":[],"resource":[]}` | Apply transformations to span metrics after they are generated. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.transform/)) |

### Processors: Batch

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.batch.maxSize | int | `0` | Maximum number of spans, metric data points, or log records to send in a single batch. This number must be greater than or equal to the `size` setting. If set to 0, the batch processor will not enforce a maximum size. |
| processors.batch.size | int | `8192` | Number of spans, metric data points, or log records after which a batch will be sent regardless of the timeout. This setting acts as a trigger and does not affect the size of the batch. If you need to enforce batch size limit, use `maxSize`. |
| processors.batch.timeout | string | `"2s"` | How long before sending (Processors) |

### Processors: Filter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.filter.errorMode | string | `"ignore"` | How to react to errors if they occur while processing a statement. Valid options are "ignore", "silent", and "propagate". |

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
| processors.k8sattributes.annotations | list | `[]` | Kubernetes annotations to extract and add to the attributes of the received telemetry data in the form of a list of otelcol.processor.k8sattributes extract > annotation blocks. See the [Alloy documentation](https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.processor.k8sattributes/#annotation-block) for details on how to configure annotation blocks. |
| processors.k8sattributes.filters.byField | list | `[]` | Only extract Kubernetes attributes for telemetry data coming from pods that match the field selectors. Each entry can have "key", "value", and "op", where "op" is one of "equals", "not-equals", "exists", or "does-not-exist". |
| processors.k8sattributes.filters.byLabel | list | `[]` | Only extract Kubernetes attributes for telemetry data coming from pods that match the label selectors. Each entry can have "key", "value", and "op", where "op" is one of "equals", "not-equals", "exists", or "does-not-exist". |
| processors.k8sattributes.filters.byNamespace | string | `""` | Only extract Kubernetes attributes for telemetry data coming from the specified Kubernetes namespace. |
| processors.k8sattributes.filters.byNode | string | `""` | Only extract Kubernetes attributes for telemetry data coming from the specified Kubernetes node. |
| processors.k8sattributes.filters.ownNode | bool | `false` | Only extract Kubernetes attributes for telemetry data coming from the same node as this Alloy instance. |
| processors.k8sattributes.labels | list | `[]` | Kubernetes labels to extract and add to the attributes of the received telemetry data in the form of a list of otelcol.processor.k8sattributes extract > label blocks. See the [Alloy documentation](https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.processor.k8sattributes/#extract-label-block) for details on how to configure label blocks. |
| processors.k8sattributes.metadata | list | `["k8s.namespace.name","k8s.pod.name","k8s.deployment.name","k8s.statefulset.name","k8s.daemonset.name","k8s.cronjob.name","k8s.job.name","k8s.node.name","k8s.pod.uid","k8s.pod.start_time"]` | Kubernetes metadata to extract and add to the attributes of the received telemetry data. |
| processors.k8sattributes.passthrough | bool | `false` | Pass through signals as-is, only adding a `k8s.pod.ip` resource attribute. |
| processors.k8sattributes.podAssociation | list | `[{"from":"resource_attribute","name":"k8s.pod.ip"},{"from":"resource_attribute","name":"k8s.pod.uid"},{"from":"connection"}]` | Defines the rules on how to associate logs/traces/metrics to Pods. |

### Processors: Memory Limiter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. |
| processors.memoryLimiter.enabled | bool | `false` | Use a memory limiter. |
| processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. |

### Processors: Resource Detection

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.resourceDetection.env.enabled | bool | `true` | Enable getting resource attributes from the OTEL_RESOURCE_ATTRIBUTES environment variable. |
| processors.resourceDetection.kubernetesNode.authType | string | `"serviceAccount"` | The authentication method. This should not be changed. |
| processors.resourceDetection.kubernetesNode.enabled | bool | `false` | Enable getting resource attributes about the Kubernetes node from the API server. |
| processors.resourceDetection.kubernetesNode.nodeFromEnvVar | string | `"K8S_NODE_NAME"` | The name of an environment variable from which to retrieve the node name. |
| processors.resourceDetection.override | bool | `true` | Configures whether existing resource attributes should be overridden or preserved. |
| processors.resourceDetection.system.enabled | bool | `true` | Enable getting resource attributes from the host machine. |
| processors.resourceDetection.system.hostnameSources | list | `["os"]` | The priority list of sources from which the hostname will be determined. Options: ["dns", "os", "cname", "lookup"]. |
| processors.resourceDetection.system.resourceAttributes | object | `{}` | The list of resource attributes to add for system resource detection. See the [Alloy documentation](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.resourcedetection/#system--resource_attributes) for a list of available attributes. |

### Processors: Transform

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.transform.errorMode | string | `"ignore"` | How to react to errors if they occur while processing a statement. Valid options are "ignore", "silent", and "propagate". |

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
| receivers.otlp.grpc.enabled | bool | `false` | Accept application data over OTLP gRPC. |
| receivers.otlp.grpc.includeMetadata | bool | `false` | Propagate incoming connection metadata to downstream consumers. |
| receivers.otlp.grpc.keepalive.enforcementPolicy.minTime | string | `""` | Minimum time clients should wait before sending a keepalive ping. Default is 5 minutes. |
| receivers.otlp.grpc.keepalive.enforcementPolicy.permitWithoutStream | bool | `false` | Allow clients to send keepalive pings when there are no active streams. |
| receivers.otlp.grpc.keepalive.serverParameters.maxConnectionAge | string | `""` | Maximum age for non-idle connections. Default is infinity. |
| receivers.otlp.grpc.keepalive.serverParameters.maxConnectionAgeGrace | string | `""` | Time to wait before forcibly closing connections. Default is infinity. |
| receivers.otlp.grpc.keepalive.serverParameters.maxConnectionIdle | string | `""` | Maximum age for idle connections. Default is infinity. |
| receivers.otlp.grpc.keepalive.serverParameters.time | string | `""` | How often to ping inactive clients to check for liveness. Default is 2 hours. |
| receivers.otlp.grpc.keepalive.serverParameters.timeout | string | `""` | Time to wait before closing inactive clients that don’t respond to liveness checks. Default is 20 seconds. |
| receivers.otlp.grpc.maxConcurrentStreams | int | `0` | Limit the number of concurrent streaming gRPC calls. 0 means no limit. |
| receivers.otlp.grpc.maxReceivedMessageSize | string | `"4MiB"` | Maximum size of messages the gRPC server will accept. |
| receivers.otlp.grpc.port | int | `4317` | The port to listen on for OTLP gRPC requests. |
| receivers.otlp.grpc.readBufferSize | string | `"512KiB"` | Size of the read buffer the gRPC server will use for reading from clients. |
| receivers.otlp.grpc.writeBufferSize | string | `"32KiB"` | Size of the write buffer the gRPC server will use for writing to clients. |
| receivers.otlp.http.enabled | bool | `false` | Accept application data over OTLP HTTP. |
| receivers.otlp.http.includeMetadata | bool | `false` | Propagate incoming connection metadata to downstream consumers. |
| receivers.otlp.http.maxRequestBodySize | string | `"20MiB"` | Maximum request body size the server will allow. |
| receivers.otlp.http.port | int | `4318` | The port to listen on for OTLP HTTP requests. |
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
<!--alex enable host-hostess-->
