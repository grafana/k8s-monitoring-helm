# Splitting Feature and Services

Since we want to be able to deploy services without prescribing the local configuration for those features, we will
separate the telemetry services from the feature subcharts. This has implications for how enabling the configuration and
helping the user know what values are required.

There are four different options when combining whether to use local config and whether to deploy the backing telemetry
service:

| Local config | Deploy Service | Situation                                                            |
|--------------|----------------|----------------------------------------------------------------------|
| `true`       | `true`         | Deploy config that uses the local service                            |
| `true`       | `false`        | Deploy the config that uses an existing service                      |
| `false`      | `true`         | Deploy the service, but no config (for later use with remote config) |
| `false`      | `false`        | Do not collect any telemetry signals from this service               |

In v3, a good example of this would be metrics from Node Exporter.

| Local config | Deploy Service | values.yaml                                                                                                                                                                               |
|--------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `true`       | `true`         | <pre>clusterMetrics:<br />  enabled: true<br />  node-exporter:<br />    enabled: true</pre>                                                                                              |
| `true`       | `false`        | <pre>clusterMetrics:<br />  enabled: true<br />  node-exporter:<br />    enabled: true<br />    deploy: false<br />    # Also configure selectors to find existing Node Exporter...</pre> |
| `false`      | `true`         | Not permitted                                                                                                                                                                             |
| `false`      | `false`        | <pre>clusterMetrics:<br />  enabled: true<br />  node-exporter:<br />    enabled: false<br />    deploy: false</pre>                                                                      |

in v4, the services are split:

### Option 1: Local config enabled with deployed service
```yaml
hostMetrics:
  enabled: true
  nodeExporter:
    enabled: true

telemetryServices:
  nodeExporter:
    deploy: true
```

### Option 2: Local config enabled with pre-existing service
```yaml
hostMetrics:
  enabled: true
  nodeExporter:
    enabled: true
    # Without the following, the deployment will fail with:
    # Please enable telemetryServices.nodeExporter, or specify the namespace and labelSelectors
    namespace: ""
    labelSelectors:
      app.kubernetes.io/name: prometheus-node-exporter

telemetryServices:
  nodeExporter:
    deploy: false  # the default
```

### Option 3: Deployed service with no local config
```yaml
telemetryServices:
  nodeExporter:
    deploy: true
```

### Option 4: No config or service
```yaml
# Nothing
```
