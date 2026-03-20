# singleton.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"replicas":1,"type":"deployment"}` | Configures Alloy to run as a single-instance, protecting workloads that would result in duplicated data if run on multiple replicas. |
<!-- textlint-enable terminology -->
