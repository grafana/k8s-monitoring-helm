# faro

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
| name | string | `""` | The name for this Faro destination. |
| proxyURL | string | `""` | HTTP proxy to send requests through |
| retryOnFailure.enabled | bool | `true` | Should failed requests be retried? |
| retryOnFailure.initialInterval | string | `"5s"` | The initial time to wait before retrying a failed request to the Faro destination. |
| retryOnFailure.maxElapsedTime | string | `"5m"` | The maximum amount of time to wait before discarding a failed batch. |
| retryOnFailure.maxInterval | string | `"30s"` | The maximum time to wait before retrying a failed request to the Faro destination. |
| url | string | `""` | The URL for the Faro destination. |
| urlFrom | string | `""` | Raw config for accessing the URL. |

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

### Transform Processor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.transform.errorMode | string | `"ignore"` | How to react to errors if they occur while processing a statement. Valid options are "ignore", "silent", and "propagate". |
| processors.transform.logs.log | list | `[]` | Log transforms |
| processors.transform.logs.logFrom | list | `[]` | Raw log transforms |
| processors.transform.logs.resource | list | `[]` | Log resource transforms |
| processors.transform.logs.resourceFrom | list | `[]` | Raw log resource transforms |
| processors.transform.traces.resource | list | `[]` | Trace resource transforms |
| processors.transform.traces.resourceFrom | list | `[]` | Raw trace resource transforms |
| processors.transform.traces.span | list | `[]` | Trace span transforms |
| processors.transform.traces.spanFrom | list | `[]` | Raw trace span transforms |
| processors.transform.traces.spanevent | list | `[]` | Trace spanevent transforms |
| processors.transform.traces.spaneventFrom | list | `[]` | Raw trace spanevent transforms |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret for this Faro destination. |
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

### TLS

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tls.ca | string | `""` | The CA certificate for the server (as a string). |
| tls.caFile | string | `""` | The CA certificate for the server (as a path to a file). |
| tls.caFrom | string | `""` | Raw config for accessing the server CA certificate. |
| tls.cert | string | `""` | The client certificate for the server (as a string). |
| tls.certFile | string | `""` | The client certificate for the server (as a path to a file). |
| tls.certFrom | string | `""` | Raw config for accessing the client certificate. |
| tls.insecure | bool | `false` | Whether to use TLS for the Faro destination. |
| tls.insecureSkipVerify | bool | `false` | Disables validation of the server certificate. |
| tls.key | string | `""` | The client key for the server (as a string). |
| tls.keyFile | string | `""` | The client key for the server (as a path to a file). |
| tls.keyFrom | string | `""` | Raw config for accessing the client key. |
<!-- textlint-enable terminology -->
