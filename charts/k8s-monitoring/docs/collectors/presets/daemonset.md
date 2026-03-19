# daemonset.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"tolerations":[{"effect":"NoSchedule","operator":"Exists"}],"type":"daemonset"}` | Configures Alloy to run as a DaemonSet, ensuring a single instance per node. |
<!-- textlint-enable terminology -->
