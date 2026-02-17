# Version 4.0 Development Plan

This doc and directory will contain the development plan and some options surrounding the upcoming major release, 4.0.

## Required major changes

### `destinations` becomes a map

The `destinations` object becomes a map, instead of a list. This will make setting and modifying this structure simpler
for users. The v3 option `destinationsMap` basically becomes the default.

Rationale: Not everyone sets the destinations in a single values.yaml file. If you set the destinations list in a values
file, then want to override with `helm install ... --set ...` or with tools like Terraform or ArgoCD, they don't need to
reference the destination by indexing and numbers.

#### v3

```yaml
destinations:
  - name: metrics
    type: prometheus
  - name: logs
    type: loki
```

#### v4

```yaml
destinations:
  metrics:
    type: prometheus
  logs:
    type: loki
```

### No more hard-coded Alloy instances

Instead of using:
* `alloy-metrics`
* `alloy-singleton`
* `alloy-logs`
* `alloy-receiver`
* `alloy-profiles`

we'll define a `collectors` map. This will allow more flexibility in creating Alloy instances. To make things easier, we
can introduce a `presets` feature that can automatically load standard 

Rationale: Bringing the same flexibility for collectors as we did with destinations. Allows for more specialized
configurations that weren't possible before.

#### v3

```yaml
alloy-metrics:
  ...

alloy-logs:
  ...
```

#### v4

```yaml
collectors:
  alloy:
    preset: metricCollector  # Enables StatefulSet & clustering

  log-collector:
    preset: fsLogCollector  # Enables DaemonSet & HostPath volume mounts
```

### Telemetry services separated from configuration

Telemetry service workloads, like kube-state-metrics, Node Exporter, Kepler, etc... will not be deployed inside their
feature subcharts. This will allow for simplified deployment of those services without requiring their associated
configuration.

Rationale: The Grafana Cloud Onboarding chart (for Insutrmentation Hub) required the telemetry data services, but did
not use any local config. For local config (k8s-monitoring), we want to deploy Alloy, KSM, and the config to scrape
KSM. For remote config (instrumentation hub), we want to deploy Alloy and KSM, but utilize Fleet Management to deliver
the configuration.

#### v3

Local config
```yaml
# This deploys kube-state-metrics, Node Exporter, Windows Exporter, and optionally Kepler and OpenCost.
clusterMetrics:
  enabled: true
```

Remote config (i.e. for Instrumentation Hub)
```yaml
# This deploys kube-state-metrics, Node Exporter, Windows Exporter, but skips the configuration
clusterMetrics:
  enabled: true
  kubelet: { enabled: false }
  kubeletResources: { enabled: false }
  cadvisor: { enabled: false }
  kube-state-metrics:
    deploy: true
    enabled: false
  node-exporter:
    deploy: true
    enabled: false
  windows-exporter:
    deploy: true
    enabled: false
```

#### v4

Local config
```yaml
collectors: {...}

# kubelet, kubeletResources, cadvisor Alloy configuration
clusterMetrics:
  enabled: true

# Node Exporter, Windows Exporter, Kepler Alloy configuration
hostMetrics:
  enabled: true

telemetryServices:
  kube-state-metrics:
    deploy: true
  nodeExporter:
    deploy: true
  windowsExporter:
    deploy: true
```

Remote config (i.e. for Instrumentation Hub)
```yaml
collectorCommon:
  remoteConfig:
    enabled: true
    url: ...
    auth: {...}

telemetryServices:
  kube-state-metrics:
    deploy: true
  nodeExporter:
    deploy: true
  windowsExporter:
    deploy: true
```
