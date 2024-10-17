# Loki Destination

This defines the options for defining a destination for logs that use the Loki protocol.

## Values

### Authentication - Bearer Token

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.bearerToken | string | `""` | The bearer token for bearer token authentication. |
| auth.bearerTokenFrom | string | `""` | Raw config for accessing the bearer token. |
| auth.bearerTokenKey | string | `"bearerToken"` | The key for storing the bearer token in the secret. |

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
| auth.type | string | none | The type of authentication to do. Options are "none" (default), "basic", "bearerToken". |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraHeaders | object | `{}` | Extra headers to be set when sending data. All values are treated as strings and automatically quoted. |
| extraHeadersFrom | object | `{}` | Extra headers to be set when sending data through a dynamic reference. All values are treated as raw strings and not quoted. |
| extraLabels | object | `{}` | Custom labels to be added to all logs and events. All values are treated as strings and automatically quoted. |
| extraLabelsFrom | object | `{}` | Custom labels to be added to all logs and events through a dynamic reference. All values are treated as raw strings and not quoted. |
| name | string | `""` | The name for this Loki destination. |
| proxyURL | string | `""` | The Proxy URL for the Loki destination. |
| tenantId | string | `""` | The tenant ID for the Loki destination. |
| tenantIdFrom | string | `""` | Raw config for accessing the tenant ID. |
| tenantIdKey | string | `"tenantId"` | The key for storing the tenant ID in the secret. |
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
