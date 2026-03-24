# privileged.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"securityContext":{"allowPrivilegeEscalation":true,"privileged":true,"runAsGroup":0,"runAsUser":0}}` | Configures Alloy to run with elevated privileges, allowing it to access system resources and perform operations that require root access. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller.hostPID | bool | `true` |  |
<!-- textlint-enable terminology -->
