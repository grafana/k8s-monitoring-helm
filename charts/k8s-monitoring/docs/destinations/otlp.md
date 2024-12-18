# OpenTelemetry Protocol Destination

This defines the options for defining a destination for OpenTelemetry data that use the OTLP protocol.

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
| auth.oauth2.clientSecret | string | `""` | Prometheus OAuth2 client secret |
| auth.oauth2.clientSecretFile | string | `""` | File containing the OAuth2 client secret. |
| auth.oauth2.clientSecretFrom | string | `""` | Raw config for accessing the client secret |
| auth.oauth2.clientSecretKey | string | `"clientSecret"` | The key for the client secret property in the secret |
| auth.oauth2.endpointParams | object | `{}` | Prometheus OAuth2 endpoint parameters |
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
| auth.type | string | `"none"` | The type of authentication to do. Options are "none" (default), "basic", "bearerToken", "oauth2". |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraHeaders | object | `{}` | Extra headers to be set when sending data. All values are treated as strings and automatically quoted. |
| extraHeadersFrom | object | `{}` | Extra headers to be set when sending data through a dynamic reference. All values are treated as raw strings and not quoted. |
| name | string | `""` | The name for this OTLP destination. |
| protocol | string | `"grpc"` | The protocol for the OTLP destination. Options are "grpc" (default), "http". |
| readBufferSize | string | `""` | Size of the read buffer the gRPC client to use for reading server responses. |
| tenantId | string | `""` | The tenant ID for the OTLP destination. |
| tenantIdFrom | string | `""` | Raw config for accessing the tenant ID. |
| tenantIdKey | string | `"tenantId"` | The key for storing the tenant ID in the secret. |
| url | string | `""` | The URL for the OTLP destination. |
| urlFrom | string | `""` | Raw config for accessing the URL. |
| writeBufferSize | string | `""` | Size of the write buffer the gRPC client to use for writing requests. |

### Telemetry

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | string | `true` | Whether to send logs to the OTLP destination. |
| metrics.enabled | string | `true` | Whether to send metrics to the OTLP destination. |
| traces.enabled | string | `true` | Whether to send traces to the OTLP destination. |

### Attributes Processor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.attributes.actions | list | `[]` | Attribute processor actions Format: { key: "", value: "", action: "", pattern: "", fromAttribute: "", fromContext: "", convertedType: "" } Can also use `valueFrom` instead of value to use a raw reference. |

### Batch Processor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.batch.enabled | bool | `true` | Whether to use a batch processor. |
| processors.batch.maxSize | int | `0` | Upper limit of a batch size. When set to 0, there is no upper limit. |
| processors.batch.size | int | `8192` | Amount of data to buffer before flushing the batch. |
| processors.batch.timeout | string | `"2s"` | How long to wait before flushing the batch. |

### Memory Limiter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. |
| processors.memoryLimiter.enabled | bool | `false` | Whether to use a memory limiter. |
| processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. |

### Transform Processor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors.transform.logs | object | `{"log":[],"resource":[]}` | Log transforms |
| processors.transform.metrics | object | `{"datapoint":[],"metric":[],"resource":[]}` | Metric transforms |
| processors.transform.traces | object | `{"resource":[],"span":[],"spanevent":[]}` | Trace transforms |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret for this Prometheus destination. |
| secret.embed | bool | `false` | If true, skip secret creation and embed the credentials directly into the configuration. |
| secret.name | string | `""` | The name of the secret to create. |
| secret.namespace | string | `""` | The namespace for the secret. |

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

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| processors | object | `{"attributes":{"actions":[]},"batch":{"enabled":true,"maxSize":0,"size":8192,"timeout":"2s"},"memoryLimiter":{"checkInterval":"1s","enabled":false,"limit":"0MiB"},"transform":{"logs":{"log":[],"resource":[]},"metrics":{"datapoint":[],"metric":[],"resource":[]},"traces":{"resource":[],"span":[],"spanevent":[]}}}` | Processors to apply to the data before sending it. |
