# Pyroscope Destination

This defines the options for defining a destination for profiles that use the Pyroscope protocol.

<!-- textlint-disable terminology -->
## Values

### Authentication - Bearer Token

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.bearerToken | string | `""` | The bearer token for bearer token authentication. |
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
| auth.type | string | `"none"` | The type of authentication to do. Options are "none" (default), "basic", "bearerToken". |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterLabels | list | `["cluster","k8s.cluster.name"]` | Labels to be set with the cluster name as the value. |
| extraHeaders | object | `{}` | Extra headers to be set when sending data. All values are treated as strings and automatically quoted. |
| extraHeadersFrom | object | `{}` | Extra headers to be set when sending data through a dynamic reference. All values are treated as raw strings and not quoted. |
| extraLabels | object | `{}` | Extra labels to be added to all profiles before delivering to the destination. All values are treated as strings and automatically quoted. |
| extraLabelsFrom | object | `{}` | Extra labels to be added to all profiles using a dynamic reference before delivering to the destination. All values are treated as raw strings and not quoted. |
| maxBackoffPeriod | string | `"5m"` | The maximum backoff period for the Pyroscope destination. |
| maxBackoffRetries | int | `10` | The maximum number of backoff retries for the Pyroscope destination. |
| minBackoffPeriod | string | `"500ms"` | The minimum backoff period for the Pyroscope destination. |
| name | string | `""` | The name for this Pyroscope destination. |
| noProxy | string | `""` | Comma-separated list of IP addresses, CIDR notations, and domain names to exclude from proxying. |
| proxyConnectHeader | object | `{}` | Specifies headers to send to proxies during CONNECT requests. |
| proxyFromEnvironment | bool | `false` | Use the proxy URL indicated by environment variables. |
| proxyURL | string | `""` | HTTP proxy to send requests through. |
| tenantId | string | `""` | The tenant ID for the Pyroscope destination. |
| tenantIdFrom | string | `""` | Raw config for accessing the tenant ID. |
| tenantIdKey | string | `"tenantId"` | The key for storing the tenant ID in the secret. |
| url | string | `""` | The URL for the Pyroscope destination. |
| urlFrom | string | `""` | Raw config for accessing the URL. |

### Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secret.create | bool | `true` | Whether to create a secret for this Pyroscope destination. |
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
