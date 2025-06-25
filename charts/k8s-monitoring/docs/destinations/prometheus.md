# Prometheus Destination

This defines the options for defining a destination for metrics that use the Prometheus remote write protocol.

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

### Authentication - SigV4

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.sigv4.accessKey | string | `""` | The access key for sigv4 authentication. |
| auth.sigv4.accessKeyFrom | string | `""` | Raw config for accessing the access key. |
| auth.sigv4.accessKeyKey | string | `"accessKey"` | The key for storing the access key in the secret. |
| auth.sigv4.profile | string | `""` | The named AWS profile for sigv4 authentication. |
| auth.sigv4.region | string | `""` | The AWS region for sigv4 authentication. |
| auth.sigv4.roleArn | string | `""` | The Role ARN for sigv4 authentication. |
| auth.sigv4.secretKey | string | `""` | The secret key for sigv4 authentication. |
| auth.sigv4.secretKeyFrom | string | `""` | Raw config for accessing the secret key. |

### Authentication - Sig

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.sigv4.secretKeyKey | string | `"secretKey"` | The key for storing the secret key in the secret. |

### Authentication

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.type | string | `"none"` | The type of authentication to do. Options are "none" (default), "basic", "bearerToken", "oauth2", "sigv4". |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterLabels | list | `["cluster","k8s.cluster.name"]` | Labels to be set with the cluster name as the value. |
| extraHeaders | object | `{}` | Extra headers to be set when sending data. All values are treated as strings and automatically quoted. |
| extraHeadersFrom | object | `{}` | Extra headers to be set when sending data using a dynamic reference. All values are treated as raw strings and not quoted. |
| extraLabels | object | `{}` | Extra labels to be added to all metrics before delivering to the destination. All values are treated as strings and automatically quoted. |
| extraLabelsFrom | object | `{}` | Extra labels to be added to all metrics using a dynamic reference before delivering to the destination. All values are treated as raw strings and not quoted. |
| metricProcessingRules | string | `""` | Rule blocks to apply to all metrics. Uses the [write_relabel_config block](https://grafana.com/docs/alloy/latest/reference/components/prometheus.remote_write/#write_relabel_config-block) of the prometheus.remote_write component. Format: write_relabel_config {   source_labels = ["..."]   action = "..."   ... } |
| name | string | `""` | The name for this Prometheus destination. |
| noProxy | string | `""` | Comma-separated list of IP addresses, CIDR notations, and domain names to exclude from proxying. |
| proxyConnectHeader | object | `{}` | Specifies headers to send to proxies during CONNECT requests. |
| proxyFromEnvironment | bool | `false` | Use the proxy URL indicated by environment variables. |
| proxyURL | string | `""` | HTTP proxy to send requests through. |
| sendNativeHistograms | bool | `false` | Whether native histograms should be sent. |
| tenantId | string | `""` | The tenant ID for the Prometheus destination. |
| tenantIdFrom | string | `""` | Raw config for accessing the tenant ID. |
| tenantIdKey | string | `"tenantId"` | The key for storing the tenant ID in the secret. |
| url | string | `""` | The URL for the Prometheus destination. |
| urlFrom | string | `""` | Raw config for accessing the URL. Lets you insert raw Alloy references so you can load the URL from any number of places, such as loading values from config maps to HTTP calls. For example: `urlFrom: sys.env("PROMETHEUS_URL")` |

### OpenTelemetry Conversion

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| openTelemetryConversion.addMetricSuffixes | bool | `true` | Whether to add type and unit suffixes to metrics names. |
| openTelemetryConversion.resourceToTelemetryConversion | bool | `false` | Whether to convert OTel resource attributes to Prometheus labels. |

### Queue Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| queueConfig.batchSendDeadline | string | `"5s"` | Maximum time samples will wait in the buffer before sending. |
| queueConfig.capacity | int | `10000` | Number of samples to buffer per shard. |
| queueConfig.maxBackoff | string | `"5s"` | Maximum retry delay. |
| queueConfig.maxSamplesPerSend | int | `2000` | Maximum number of samples per send. |
| queueConfig.maxShards | int | `50` | Maximum amount of concurrent shards sending samples to the endpoint. |
| queueConfig.minBackoff | string | `"30ms"` | Initial retry delay. The backoff time gets doubled for each retry. |
| queueConfig.minShards | int | `1` | Minimum amount of concurrent shards sending samples to the endpoint. |
| queueConfig.retryOnHttp429 | bool | `true` | Retry when an HTTP 429 status code is received. |
| queueConfig.sampleAgeLimit | string | `"0s"` | Maximum age of samples to send. |

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
| tls.insecureSkipVerify | bool | `false` | Disables validation of the server certificate. |
| tls.key | string | `""` | The client key for the server (as a string). |
| tls.keyFile | string | `""` | The client key for the server (as a path to a file). |
| tls.keyFrom | string | `""` | Raw config for accessing the client key. |

### Write-Ahead Log

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| writeAheadLog.maxKeepaliveTime | string | `"8h"` | Maximum time to keep data in the write-ahead log before removing it. |
| writeAheadLog.minKeepaliveTime | string | `"5m"` | Minimum time to keep data in the write-ahead log before it can be removed. |
| writeAheadLog.truncateFrequency | string | `"2h"` | How frequently to clean up the write-ahead log. |
<!-- textlint-enable terminology -->

## Examples

### Local Prometheus

```yaml
destinations:
- name: localPrometheus
  type: prometheus
  url: http://prometheus.monitoring.svc.cluster.local:9090
```

### Prometheus with Basic Auth

```yaml
destinations:
- name: CloudHostedMetrics
  type: prometheus
  url: https://prometheus.example.com/api/prom/push
  auth:
    type: basic
    username: "my-username"
    password: "my-password"
```

### Prometheus with embedded Bearer Token

```yaml
destinations:
- name: promWithBearerToken
  type: prometheus
  url: https://prometheus.example.com/api/prom/push
  auth:
    type: bearerToken
    bearerToken: my-token
  secret:
    embed: true
```
