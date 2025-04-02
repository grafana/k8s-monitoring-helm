# alloy

## Values

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraConfig | string | `""` | Extra Alloy configuration to be added to the configuration file. |
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
| remoteConfig.url | string | `""` | The URL of the remote config server. |

### Remote Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| remoteConfig.enabled | bool | `false` | Enable fetching configuration from a remote config server. |
| remoteConfig.extraAttributes | object | `{}` | Attributes to be added to this collector when requesting configuration. |
| remoteConfig.pollFrequency | string | `"5m"` | The frequency at which to poll the remote config server for updates. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| crds.create | bool | `false` |  |
