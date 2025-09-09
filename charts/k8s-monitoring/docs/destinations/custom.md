# custom

<!-- textlint-disable terminology -->
## Values

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | The name for this custom destination. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config | string | `""` | The configuration for this destination. @ section -- General |
| ecosystem | string | `""` | The ecosystem for this destination. By setting this ecosystem, matching telemetry data sources might be auto-assigned to this destination. Options: `loki`, `otlp`, `prometheus`, `pyroscope` @ section -- General |
| logs.enabled | bool | `false` | Enable sending logs to this destination. @ section -- Logs |
| logs.target | string | `""` | The Alloy component reference for sending logs. @ section -- Logs |
| metrics.enabled | bool | `false` | Enable sending metrics to this destination. @ section -- Metrics |
| metrics.target | string | `""` | The Alloy component reference for sending metrics. @ section -- Metrics |
| profiles.enabled | bool | `false` | Enable sending profiles to this destination. @ section -- Profiles |
| profiles.target | string | `""` | The Alloy component reference for sending profiles. @ section -- Profiles |
| traces.enabled | bool | `false` | Enable sending traces to this destination. @ section -- Traces |
| traces.target | string | `""` | The Alloy component reference for sending traces. @ section -- Traces |
<!-- textlint-enable terminology -->
