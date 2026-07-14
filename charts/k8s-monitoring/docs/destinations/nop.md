# nop

<!-- textlint-disable terminology -->
## Values

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| disabled | bool | `false` | Set to `true` to disable this destination. Disabled destinations are excluded from all telemetry data flows, which is useful for removing a destination that was defined in a shared or parent values file. |
| name | string | `""` | The name for this no-op destination. |

### Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs | object | `{"enabled":true}` | Drop all logs sent to this destination. |
| logs.enabled | bool | `true` | Whether this destination will accept and drop logs. |

### Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics | object | `{"enabled":true}` | Drop all metrics sent to this destination. |
| metrics.enabled | bool | `true` | Whether this destination will accept and drop metrics. |

### Profiles

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| profiles | object | `{"enabled":true}` | Drop all profiles sent to this destination. |
| profiles.enabled | bool | `true` | Whether this destination will accept and drop profiles. |

### Traces

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| traces | object | `{"enabled":true}` | Drop all traces sent to this destination. |
| traces.enabled | bool | `true` | Whether this destination will accept and drop traces. |
<!-- textlint-enable terminology -->
