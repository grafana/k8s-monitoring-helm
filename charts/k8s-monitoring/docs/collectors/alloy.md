# alloy

<!-- textlint-disable terminology -->
## Values

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| enabled | bool | `false` | Enable this Alloy instance. |
| extraConfig | string | `""` | Extra Alloy configuration to be added to the configuration file. |
| includeDestinations | list | `[]` | Include the configuration components for these destinations. Configuration is already added for destinations used By enabled features on this collector. This is useful when referencing destinations in the extraConfig. |
| liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |

### Logging

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Remote Configuration: Authentication

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| remoteConfig.auth.password | string | `""` | The password to use for the remote config server. |
| remoteConfig.auth.passwordFrom | string | `""` | Raw config for accessing the password. |
| remoteConfig.auth.passwordKey | string | `"password"` | The key for storing the password in the secret. |
| remoteConfig.auth.type | string | `"none"` | The type of authentication to use for the remote config server. |
| remoteConfig.auth.username | string | `""` | The username to use for the remote config server. |
| remoteConfig.auth.usernameFrom | string | `""` | Raw config for accessing the password. |
| remoteConfig.auth.usernameKey | string | `"username"` | The key for storing the username in the secret. |
| remoteConfig.secret.create | bool | `true` | Whether to create a secret for the remote config server. |
| remoteConfig.secret.embed | bool | `false` | If true, skip secret creation and embed the credentials directly into the configuration. |
| remoteConfig.secret.name | string | `""` | The name of the secret to create. |
| remoteConfig.secret.namespace | string | `""` | The namespace for the secret. |

### Remote Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| remoteConfig.enabled | bool | `false` | Enable fetching configuration from a remote config server. |
| remoteConfig.extraAttributes | object | `{}` | Attributes to be added to this collector when requesting configuration. |
| remoteConfig.noProxy | string | `""` | Comma-separated list of IP addresses, CIDR notations, and domain names to exclude from proxying. |
| remoteConfig.pollFrequency | string | `"5m"` | The frequency at which to poll the remote config server for updates. |
| remoteConfig.proxyConnectHeader | object | `{}` | Specifies headers to send to proxies during CONNECT requests. |
| remoteConfig.proxyFromEnvironment | bool | `false` | Use the proxy URL indicated by environment variables. |
| remoteConfig.proxyURL | string | `""` | The proxy URL to use of the remote config server. |
| remoteConfig.url | string | `""` | The URL of the remote config server. |
<!-- textlint-enable terminology -->
