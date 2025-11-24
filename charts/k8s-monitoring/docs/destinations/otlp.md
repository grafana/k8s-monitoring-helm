# OpenTelemetry Protocol Destination

This defines the options for defining a destination for OpenTelemetry data that use the OTLP protocol.

<!-- textlint-disable terminology -->
## Values

### Authentication - Bearer Token

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.bearerToken | string | `""` | The bearer token for bearer token authentication. |
| auth.bearerTokenFile | string | `""` | Path to a file that containers the bearer token. |
| auth.bearerTokenFrom | string | `""` | Raw config for accessing the bearer token. |
| auth.bearerTokenKey | string | `"bearerToken"` | The key for storing the bearer token in the secret. |

### Authentication - OAuth2

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.oauth2.clientId | string | `""` | OAuth2 client ID |
| auth.oauth2.clientIdFrom | string | `""` | Raw config for accessing the client ID |
| auth.oauth2.clientIdKey | string | `"clientId"` | The key for the client ID property in the secret |
| auth.oauth2.clientSecret | string | `""` | OAuth2 client secret |
| auth.oauth2.clientSecretFile | string | `""` | File containing the OAuth2 client secret. |
| auth.oauth2.clientSecretFrom | string | `""` | Raw config for accessing the client secret |
| auth.oauth2.clientSecretKey | string | `"clientSecret"` | The key for the client secret property in the secret |
| auth.oauth2.endpointParams | object | `{}` | OAuth2 endpoint parameters |
| auth.oauth2.noProxy | string | `""` | Comma-separated list of IP addresses, CIDR notations, and domain names to exclude from proxying. |
| auth.oauth2.proxyConnectHeader | object | `{}` | Specifies headers to send to proxies during CONNECT requests. |
| auth.oauth2.proxyFromEnvironment | bool | `false` | Use the proxy URL indicated by environment variables. |
| auth.oauth2.proxyURL | string | `""` | HTTP proxy to send requests through. |
| auth.oauth2.scopes | list | `[]` | List of scopes to authenticate with. |
| auth.oauth2.tokenURL | string | `""` | URL to fetch the token from. |

### Authentication - Basic

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.password | string | `""` | The password for basic authentication. |
| auth.passwordFrom | string | `""` | Raw config for accessing the password. |
| auth.passwordKey | string | `"password"` | The key for storing the password in the secret. |
| auth.username | string | `""` | The username for basic authentication. |
| auth.usernameFrom | string | `""` | Raw config for accessing the username. |
| auth.usernameKey | string | `"username"` | The key for storing the username in the secret. |

### Authentication

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.type | string | `"none"` | The type of authentication to do. Options are "none" (default), "basic", "bearerToken", "oauth2", "sigv4". |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterLabels | list | `["cluster","k8s.cluster.name"]` | Labels to be set with the cluster name as the value. |
| extraHeaders | object | `{}` | Extra headers to be set when sending data. All values are treated as strings and automatically quoted. |
| extraHeadersFrom | object | `{}` | Extra headers to be set when sending data through a dynamic reference. All values are treated as raw strings and not quoted. |
| name | string | `""` | The name for this OTLP destination. |
| protocol | string | `"grpc"` | The protocol for the OTLP destination. Options are "grpc" (default), "http". |
| proxyURL | string | `""` | HTTP proxy to send requests through, only when using the `http` protocol. |
| readBufferSize | string | `""` | Size of the read buffer the gRPC client to use for reading server responses. |
| retryOnFailure.enabled | bool | `true` | Should failed requests be retried? |
| retryOnFailure.initialInterval | string | `"5s"` | The initial time to wait before retrying a failed request to the OTLP destination. |
| retryOnFailure.maxElapsedTime | string | `"5m"` | The maximum amount of time to wait before discarding a failed batch. |
| retryOnFailure.maxInterval | string | `"30s"` | The maximum time to wait before retrying a failed request to the OTLP destination. |
| tenantId | string | `""` | The tenant ID for the OTLP destination. |
| tenantIdFrom | string | `""` | Raw config for accessing the tenant ID. |
| tenantIdKey | string | `"tenantId"` | The key for storing the tenant ID in the secret. |
| url | string | `""` | The URL for the OTLP destination. |
| urlFrom | string | `""` | Raw config for accessing the URL. |
| writeBufferSize | string | `""` | Size of the write buffer the gRPC client to use for writing requests. |

### Telemetry

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `true` | Whether to send logs to the OTLP destination. |
| metrics.enabled | bool | `true` | Whether to send metrics to the OTLP destination. |
| traces.enabled | bool | `true` | Whether to send traces to the OTLP destination. |

### Attributes Processor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.attributes.actions | list | `[]` | Attribute processor actions Format: { key: "", value: "", action: "", pattern: "", fromAttribute: "", fromContext: "", convertedType: "" } Can also use `valueFrom` instead of value to use a raw reference. |

### Batch Processor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.batch.enabled | bool | `true` | Whether to use a batch processor. |
| processors.batch.maxSize | int | `0` | Maximum number of spans, metric data points, or log records to send in a single batch. This number must be greater than or equal to the `size` setting. If set to 0, the batch processor will not enforce a maximum size. |
| processors.batch.size | int | `8192` | Number of spans, metric data points, or log records after which a batch will be sent regardless of the timeout. This setting acts as a trigger and does not affect the size of the batch. If you need to enforce batch size limit, use `maxSize`. |
| processors.batch.timeout | string | `"2s"` | How long to wait before flushing the batch. |

### Filter Processor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.filters.enabled | bool | `false` | Enable the filter processor. Any rules that evaluate to true will drop the matching telemetry data. |
| processors.filters.errorMode | string | `"ignore"` | How to react to errors if they occur while processing a statement. Valid options are "ignore", "silent", and "propagate". |
| processors.filters.logs | object | `{"logRecord":[]}` | Log filters |
| processors.filters.metrics | object | `{"datapoint":[],"metric":[]}` | Metric filters |
| processors.filters.traces | object | `{"span":[],"spanevent":[]}` | Trace filters |

### Memory Limiter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. |
| processors.memoryLimiter.enabled | bool | `false` | Whether to use a memory limiter. |
| processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. |

### Resource Attributes Processor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.resourceAttributes.removeList | list | `[]` | List of additional resource attribute names to remove from OTEL signals These attributes will be deleted from the resource context for all signal types (metrics, logs, traces) |
| processors.resourceAttributes.useDefaultRemoveList | bool | `true` | Whether to use the default remove list for resource attributes |

### Service Graph Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.serviceGraphMetrics.cacheLoop | string | `"1m"` | Configures how often to delete series which haven’t been updated. |
| processors.serviceGraphMetrics.collector | object | `{"alloy":{},"controller":{"replicas":2,"type":"statefulset"}}` | Settings for the Alloy instance that will handle service graph metrics. |
| processors.serviceGraphMetrics.databaseNameAttribute | string | `""` | The attribute name used to identify the database name from span attributes. DEPRECATED: Please use databaseNameAttributes instead. If this is provided, it will override databaseNameAttributes as the only attribute to used. |
| processors.serviceGraphMetrics.databaseNameAttributes | list | `["db.name"]` | The attribute names used to identify the database name from span attributes. |
| processors.serviceGraphMetrics.destinations | list | `[]` | The destinations where service graph metrics will be sent. If empty, all metrics-capable destinations will be used. |
| processors.serviceGraphMetrics.dimensions | list | `["cloud.availability_zone","cloud.region","deployment.environment","k8s.cluster.name","k8s.namespace.name","service.namespace","service.version"]` | A list of dimensions to add with the default dimensions. |
| processors.serviceGraphMetrics.enabled | bool | `false` | Generate service graph metrics from traces. This will deploy an additional Alloy instance to handle service graph metrics generation. Traces sent to this destination will be aumatically forwarded, using a load balancer component, to this Alloy instance. |
| processors.serviceGraphMetrics.latencyHistogramBuckets | list | `["2ms","4ms","6ms","8ms","10ms","50ms","100ms","200ms","400ms","800ms","1s","1400ms","2s","5s","10s","15s"]` | Buckets for latency histogram metrics. |
| processors.serviceGraphMetrics.metricsFlushInterval | string | `"60s"` | The interval at which metrics are flushed to downstream components. |
| processors.serviceGraphMetrics.receiver | object | `{"otlp":{"grpc":{"maxReceivedMessageSize":"4MB"}}}` | The service graph otlp receiver configuration. |
| processors.serviceGraphMetrics.storeExpirationLoop | string | `"2s"` | The time to expire old entries from the store periodically. |

### Tail Sampling

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.tailSampling.collector | object | `{"alloy":{},"controller":{"replicas":2,"type":"statefulset"}}` | Settings for the Alloy instance that will handle tail sampling. |
| processors.tailSampling.decisionCache | object | `{"nonSampledCacheSize":0,"sampledCacheSize":0}` | The decision cache for the tail sampling. When you use decision_cache, configure it with a much higher value than num_traces so decisions for trace IDs are kept longer than the span data for the trace. |
| processors.tailSampling.decisionCache.nonSampledCacheSize | int | `0` | Configures amount of trace IDs to be kept in an LRU cache, persisting the "drop" decisions for traces that may have already been released from memory. By default, the size is 0 and the cache is inactive. |
| processors.tailSampling.decisionCache.sampledCacheSize | int | `0` | Configures amount of trace IDs to be kept in an LRU cache, persisting the "keep" decisions for traces that may have already been released from memory. By default, the size is 0 and the cache is inactive. |
| processors.tailSampling.decisionWait | string | `"15s"` | Wait time since the first span of a trace before making a sampling decision. |
| processors.tailSampling.enabled | bool | `false` | Apply tail sampling policies to the traces before delivering them to this destination. This will create an additional Alloy instance to handle the tail sampling, and traces sent to this destination will be automatically forwarded, using a load balancer component, to the new sampling Alloy instance. |
| processors.tailSampling.expectedNewTracesPerSec | int | `0` | Expected number of new traces (helps in allocating data structures). |
| processors.tailSampling.numTraces | int | `0` | Determines the buffer size of the trace delete channel which is composed of trace IDs that are being deleted. Default is 0, which means no buffer is used. |
| processors.tailSampling.policies | list | `[]` | Tail sampling policies to apply. |
| processors.tailSampling.receiver | object | `{"otlp":{"grpc":{"maxReceivedMessageSize":"4MB"}}}` | The tail sampling otlp receiver configuration. |

### Transform Processor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.transform.errorMode | string | `"ignore"` | How to react to errors if they occur while processing a statement. Valid options are "ignore", "silent", and "propagate". |
| processors.transform.logs.log | list | `[]` | Log transforms |
| processors.transform.logs.logFrom | list | `[]` | Raw log transforms |
| processors.transform.logs.logToResource | object | `{"container":"k8s.container.name","cronjob":"k8s.cronjob.name","daemonset":"k8s.daemonset.name","deployment":"k8s.deployment.name","deployment_environment":"deployment.environment","deployment_environment_name":"deployment.environment.name","job_name":"k8s.job.name","namespace":"k8s.namespace.name","pod":"k8s.pod.name","replicaset":"k8s.replicaset.name","service_name":"service.name","service_namespace":"service.namespace","statefulset":"k8s.statefulset.name"}` | Promote certain log attributes to resource attributes. This is helpful for translating log data from Loki sources to OTLP format. Format: `{ <log attribute name>: <resource attribute name> }`. Will not copy if the resource attribute already exists. |
| processors.transform.logs.resource | list | `[]` | Log resource transforms |
| processors.transform.logs.resourceFrom | list | `[]` | Raw log resource transforms |
| processors.transform.metrics.datapoint | list | `[]` | Metric datapoint transforms |
| processors.transform.metrics.datapointFrom | list | `[]` | Raw metric datapoint transforms |
| processors.transform.metrics.datapointToResource | object | `{"deployment_environment":"deployment.environment","deployment_environment_name":"deployment.environment.name","service_name":"service.name","service_namespace":"service.namespace"}` | Promote certain metric datapoint attributes to resource attributes. This is helpful for translating metric data from Prometheus sources to OTLP format. Format: `{ <datapoint attribute name>: <resource attribute name> }`. Will not copy if the resource attribute already exists. |
| processors.transform.metrics.metric | list | `[]` | Metric transforms |
| processors.transform.metrics.metricFrom | list | `[]` | Raw metric transforms |
| processors.transform.metrics.resource | list | `[]` | Metric resource transforms |
| processors.transform.metrics.resourceFrom | list | `[]` | Raw metric resource transforms |
| processors.transform.traces.resource | list | `[]` | Trace resource transforms |
| processors.transform.traces.resourceFrom | list | `[]` | Raw trace resource transforms |
| processors.transform.traces.span | list | `[]` | Trace span transforms |
| processors.transform.traces.spanFrom | list | `[]` | Raw trace span transforms |
| processors.transform.traces.spanevent | list | `[]` | Trace spanevent transforms |
| processors.transform.traces.spaneventFrom | list | `[]` | Raw trace spanevent transforms |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret for this Prometheus destination. |
| secret.embed | bool | `false` | If true, skip secret creation and embed the credentials directly into the configuration. |
| secret.name | string | `""` | The name of the secret to create. |
| secret.namespace | string | `""` | The namespace for the secret. |

### Authentication - SigV4

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.sigv4.assumeRole.arn | string | `""` | The Amazon Resource Name (ARN) of a role to assume. |
| secret.sigv4.assumeRole.sessionName | string | `""` | The name of a role session. |
| secret.sigv4.assumeRole.stsRegion | string | `""` | The AWS region where STS is used to assume the configured role. |
| secret.sigv4.region | string | `""` | The AWS region for sigv4 authentication. |
| secret.sigv4.service | string | `""` | The AWS service for sigv4 authentication. |

### Sending Queue - Batch

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| sendingQueue.batch.enabled | bool | `false` | Should a batch mechanism be used with the sending queue? |
| sendingQueue.batch.flushTimeout | string | `""` | Time after which a batch will be sent regardless of its size. Must be a non-zero value. |
| sendingQueue.batch.maxSize | string | `nil` | The maximum size of a batch, enables batch splitting. |
| sendingQueue.batch.minSize | string | `nil` | The minimum size of a batch, enables batch splitting. |
| sendingQueue.batch.sizer | string | `""` | How the queue and batching is measured. Overrides the sizer set at the sendingQueue level for batching. Valid options are "bytes" or "items". |

### Sending Queue

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| sendingQueue.blockOnOverflow | string | false | The behavior when the component’s TotalSize limit is reached |
| sendingQueue.enabled | bool | `true` | Enables a buffer before sending data to the client. |
| sendingQueue.numConsumers | string | 10 | Number of readers to send batches written to the queue in parallel. |
| sendingQueue.queueSize | string | 1000 | Maximum number of unwritten batches allowed in the queue at the same time. |
| sendingQueue.sizer | string | requests | How the queue and batching is measured. |
| sendingQueue.storage | string | `""` | Handler from an otelcol.storage component to use to enable a persistent queue mechanism. To use this, create a storage component in extraConfig and reference it here. |
| sendingQueue.waitForResult | string | false | Determines if incoming requests are blocked until the request is processed or not. |

### TLS

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tls.ca | string | `""` | The CA certificate for the server (as a string). |
| tls.caFile | string | `""` | The CA certificate for the server (as a path to a file). |
| tls.caFrom | string | `""` | Raw config for accessing the server CA certificate. |
| tls.cert | string | `""` | The client certificate for the server (as a string). |
| tls.certFile | string | `""` | The client certificate for the server (as a path to a file). |
| tls.certFrom | string | `""` | Raw config for accessing the client certificate. |
| tls.insecure | bool | `false` | Whether to use TLS for the OTLP destination. |
| tls.insecureSkipVerify | bool | `false` | Disables validation of the server certificate. |
| tls.key | string | `""` | The client key for the server (as a string). |
| tls.keyFile | string | `""` | The client key for the server (as a path to a file). |
| tls.keyFrom | string | `""` | Raw config for accessing the client key. |
<!-- textlint-enable terminology -->
