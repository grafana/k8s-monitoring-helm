# Loki Destination

This defines the options for defining a destination for logs that use the Loki protocol.

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
| auth.type | string | `"none"` | The type of authentication to do. Options are "none" (default), "basic", "bearerToken", "oauth2". |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| batchSize | string | `""` | Maximum batch size of logs to accumulate before sending. |
| batchWait | string | `""` | Maximum amount of time to wait before sending a batch. |
| clusterLabels | list | `["cluster","k8s.cluster.name"]` | Labels to be set with the cluster name as the value. |
| extraHeaders | object | `{}` | Extra headers to be set when sending data. All values are treated as strings and automatically quoted. |
| extraHeadersFrom | object | `{}` | Extra headers to be set when sending data through a dynamic reference. All values are treated as raw strings and not quoted. |
| extraLabels | object | `{}` | Custom labels to be added to all logs and events. All values are treated as strings and automatically quoted. |
| extraLabelsFrom | object | `{}` | Custom labels to be added to all logs and events through a dynamic reference. All values are treated as raw strings and not quoted. |
| logProcessingStages | string | `""` | Stage blocks to be evaluated before delivering to the Loki destination. See ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#blocks)) for more information. |
| maxBackoffPeriod | string | `"5m"` | The maximum backoff period for the Loki destination. |
| maxBackoffRetries | int | `10` | The maximum number of backoff retries for the Loki destination. |
| minBackoffPeriod | string | `"500ms"` | The minimum backoff period for the Loki destination. |
| name | string | `""` | The name for this Loki destination. |
| noProxy | string | `""` | Comma-separated list of IP addresses, CIDR notations, and domain names to exclude from proxying. |
| proxyConnectHeader | object | `{}` | Specifies headers to send to proxies during CONNECT requests. |
| proxyFromEnvironment | bool | `false` | Use the proxy URL indicated by environment variables. |
| proxyURL | string | `""` | HTTP proxy to send requests through. |
| retryOnHttp429 | bool | `true` | Retry when an HTTP 429 status code is received. |
| tenantId | string | `""` | The tenant ID for the Loki destination. |
| tenantIdFrom | string | `""` | Raw config for accessing the tenant ID. |
| tenantIdKey | string | `"tenantId"` | The key for storing the tenant ID in the secret. |
| timeout | string | `10s` | Timeout for requests made to the URL. |
| url | string | `""` | The URL for the Loki destination. |
| urlFrom | string | `""` | Raw config for accessing the URL. |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret for this Loki destination. |
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
<!-- textlint-enable terminology -->

## Examples

### Local Loki

```yaml
destinations:
- name: localLoki
  type: loki
  url: http://loki.monitoring.svc.cluster.local:3100
```

### Loki with Basic Auth

```yaml
destinations:
- name: CloudHostedLogs
  type: loki
  url: https://prometheus.example.com/loki/api/v1/push
  auth:
    type: basic
    username: "my-username"
    password: "my-password"
```

### Loki with embedded Bearer Token

```yaml
destinations:
- name: lokiWithBearerToken
  type: loki
  url: https://loki.example.com/loki/api/v1/push
  auth:
    type: bearerToken
    bearerToken: my-token
  secret:
    embed: true
```
