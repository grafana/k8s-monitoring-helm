<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring

![Version: 2.0.5](https://img.shields.io/badge/Version-2.0.5-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.0.5](https://img.shields.io/badge/AppVersion-2.0.5-informational?style=flat-square)

Capture all telemetry data from your Kubernetes cluster.

## Usage

### Setup Grafana chart repository

```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Build your values

There are some required values that will need to be used with this chart. The basic structure of the values file is:

```yaml
cluster: {} # Cluster configuration, including the cluster name

destinations: [] # List of destinations where telemetry data will be sent

# Features to enable, which determines what data to collect
clusterMetrics: {}
clusterEvents: {}
# etc...
...

# Telemetry collector definitions
alloy-metrics: {}
alloy-singleton: {}
```

Here is more detail about the different sections:

#### Cluster

This section defines the name of your cluster, which will be set as labels to all telemetry data.

```yaml
cluster:
  name: my-cluster
```

#### Destinations

([Documentation](./docs/destinations/README.md))

This section defines the destinations for your telemetry data. You can configure multiple destinations for logs,
metrics, and traces. Here are the supported destination types:

| Type         | Protocol         | Telemetry Data        | Docs                                      |
|--------------|------------------|-----------------------|-------------------------------------------|
| `prometheus` | Remote Write     | Metrics               | [Docs](./docs/destinations/prometheus.md) |
| `loki`       | Loki             | Logs                  | [Docs](./docs/destinations/loki.md)       |
| `otlp`       | OTLP or OTLPHTTP | Metrics, Logs, Traces | [Docs](./docs/destinations/otlp.md)       |
| `pyroscope`  | Pyroscope        | Profiles              | [Docs](./docs/destinations/pyroscope.md)  |

Here is an example of a destinations section:

```yaml
destinations:
  - name: hostedMetrics
    type: prometheus
    url: https://prometheus.example.com/api/prom/push
    auth:
      type: basic
      username: "my-username"
      password: "my-password"
  - name: localPrometheus
    type: prometheus
    url: http://prometheus.monitoring.svc.cluster.local:9090
  - name: hostedLogs
    type: loki
    url: https://loki.example.com/loki/api/v1/push
    auth:
      type: basic
      username: "my-username"
      password: "my-password"
      tenantIdFrom: env("LOKI_TENANT_ID")
```

#### Features

([Documentation](./docs/Features.md))

This section is where you define which features you want to enable with this chart.

Here is an example of enabling some features:

```yaml
clusterMetrics:
  enabled: true

clusterEvents:
  enabled: true

podLogs:
  enabled: true
```

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
| rlankfo | <robert.lankford@grafana.com> |  |

<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring>
<!-- markdownlint-enable list-marker-space -->

## Requirements

| Repository | Name | Version |
|------------|------|---------|
|  | annotationAutodiscovery(feature-annotation-autodiscovery) | 1.0.0 |
|  | applicationObservability(feature-application-observability) | 1.0.0 |
|  | autoInstrumentation(feature-auto-instrumentation) | 1.0.0 |
|  | clusterEvents(feature-cluster-events) | 1.0.0 |
|  | clusterMetrics(feature-cluster-metrics) | 1.0.0 |
|  | integrations(feature-integrations) | 1.0.0 |
|  | nodeLogs(feature-node-logs) | 1.0.0 |
|  | podLogs(feature-pod-logs) | 1.0.0 |
|  | profiling(feature-profiling) | 1.0.0 |
|  | prometheusOperatorObjects(feature-prometheus-operator-objects) | 1.0.0 |
<!-- markdownlint-enable no-bare-urls -->

## Values

### Collectors - Alloy Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-logs.controller.type | string | `"daemonset"` | The type of controller to use for the Alloy Logs instance. |
| alloy-logs.enabled | bool | `false` | Deploy the Alloy instance for collecting log data. |

### Collectors - Alloy Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-metrics.controller.replicas | int | `1` | The number of replicas for the Alloy Metrics instance. |
| alloy-metrics.controller.type | string | `"statefulset"` | The type of controller to use for the Alloy Metrics instance. |
| alloy-metrics.enabled | bool | `false` | Deploy the Alloy instance for collecting metrics. |

### Collectors - Alloy Profiles

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-profiles.controller.type | string | `"daemonset"` | The type of controller to use for the Alloy Profiles instance. |
| alloy-profiles.enabled | bool | `false` | Deploy the Alloy instance for gathering profiles. |

### Collectors - Alloy Receiver

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-receiver.alloy.extraPorts | list | `[]` | The ports to expose for the Alloy receiver. |
| alloy-receiver.controller.type | string | `"daemonset"` | The type of controller to use for the Alloy Receiver instance. |
| alloy-receiver.enabled | bool | `false` | Deploy the Alloy instance for opening receivers to collect application data. |

### Collectors - Alloy Singleton

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-singleton.controller.replicas | int | `1` | The number of replicas for the Alloy Singleton instance. This should remain a single instance to avoid duplicate data. |
| alloy-singleton.controller.type | string | `"deployment"` | The type of controller to use for the Alloy Singleton instance. |
| alloy-singleton.enabled | bool | `false` | Deploy the Alloy instance for data sources required to be deployed on a single replica. |

### Features - Annotation Autodiscovery

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotationAutodiscovery | object | Disabled | Annotation Autodiscovery enables gathering metrics from Kubernetes Pods and Services discovered by special annotations. Requires a destination that supports metrics. To see the valid options, please see the [Annotation Autodiscovery feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-annotation-autodiscovery). |
| annotationAutodiscovery.destinations | list | `[]` | The destinations where cluster metrics will be sent. If empty, all metrics-capable destinations will be used. |
| annotationAutodiscovery.enabled | bool | `false` | Enable gathering metrics from Kubernetes Pods and Services discovered by special annotations. |

### Features - Application Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| applicationObservability | object | Disabled | Application Observability. Requires destinations that supports metrics, logs, and traces. To see the valid options, please see the [Application Observability feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability). |
| applicationObservability.destinations | list | `[]` | The destinations where application data will be sent. If empty, all capable destinations will be used. |
| applicationObservability.enabled | bool | `false` | Enable gathering Kubernetes Pod logs. |

### Features - Auto-Instrumentation

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoInstrumentation | object | Disabled | Auto-Instrumentation. Requires destinations that supports metrics, logs, and traces. To see the valid options, please see the [Auto-Instrumentation feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-auto-instrumentation). |
| autoInstrumentation.destinations | list | `[]` | The destinations where application data will be sent. If empty, all capable destinations will be used. |
| autoInstrumentation.enabled | bool | `false` | Enable automatic instrumentation for applications. |

### Cluster

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cluster.name | string | `""` | The name for this cluster. |

### Features - Cluster Events

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterEvents | object | Disabled | Cluster events. Requires a destination that supports logs. To see the valid options, please see the [Cluster Events feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cluster-events). |
| clusterEvents.destinations | list | `[]` | The destinations where cluster events will be sent. If empty, all logs-capable destinations will be used. |
| clusterEvents.enabled | bool | `false` | Enable gathering Kubernetes Cluster events. |

### Features - Cluster Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterMetrics | object | Disabled | Cluster Monitoring enables observability and monitoring for your Kubernetes Cluster itself. Requires a destination that supports metrics. To see the valid options, please see the [Cluster Monitoring feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cluster-metrics). |
| clusterMetrics.destinations | list | `[]` | The destinations where cluster metrics will be sent. If empty, all metrics-capable destinations will be used. |
| clusterMetrics.enabled | bool | `false` | Enable gathering Kubernetes Cluster metrics. |

### Destinations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| destinations | list | `[]` | The list of destinations where telemetry data will be sent. See the [destinations documentation](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/destinations/README.md) for more information. |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.alloyModules.branch | string | `"main"` | If using git, the branch of the git repository to use. |
| global.alloyModules.source | string | `"configMap"` | The source of the Alloy modules. The valid options are "configMap" or "git" |
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |

### Features - Service Integrations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| integrations | object | No integrations enabled | Service Integrations enables gathering telemetry data for common services and applications deployed to Kubernetes. To see the valid options, please see the [Service Integrations documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-integrations). |
| integrations.destinations | list | `[]` | The destinations where integration metrics will be sent. If empty, all metrics-capable destinations will be used. |

### Features - Node Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nodeLogs | object | Disabled | Node logs. Requires a destination that supports logs. To see the valid options, please see the [Node Logs feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-node-logs). |
| nodeLogs.destinations | list | `[]` | The destinations where logs will be sent. If empty, all logs-capable destinations will be used. |
| nodeLogs.enabled | bool | `false` | Enable gathering Kubernetes Cluster Node logs. |

### Features - Pod Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| podLogs | object | Disabled | Pod logs. Requires a destination that supports logs. To see the valid options, please see the [Pod Logs feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-pod-logs). |
| podLogs.destinations | list | `[]` | The destinations where logs will be sent. If empty, all logs-capable destinations will be used. |
| podLogs.enabled | bool | `false` | Enable gathering Kubernetes Pod logs. |

### Features - Profiling

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| profiling | object | Disabled | Profiling enables gathering profiles from applications. Requires a destination that supports profiles. To see the valid options, please see the [Profiling feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-profiling). |
| profiling.destinations | list | `[]` | The destinations where profiles will be sent. If empty, all profiles-capable destinations will be used. |
| profiling.enabled | bool | `false` | Enable gathering profiles from applications. |

### Features - Prometheus Operator Objects

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| prometheusOperatorObjects | object | Disabled | Prometheus Operator Objects enables the gathering of metrics from objects like Probes, PodMonitors, and ServiceMonitors. Requires a destination that supports metrics. To see the valid options, please see the [Prometheus Operator Objects feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-prometheus-operator-objects). |
| prometheusOperatorObjects.destinations | list | `[]` | The destinations where metrics will be sent. If empty, all metrics-capable destinations will be used. |
| prometheusOperatorObjects.enabled | bool | `false` | Enable gathering metrics from Prometheus Operator Objects. |

### Features - Self-reporting

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| selfReporting.destinations | list | `[]` | The destinations where self-report metrics will be sent. If empty, all metrics-capable destinations will be used. |
| selfReporting.enabled | bool | `true` | Enable Self-reporting. |
| selfReporting.scrapeInterval | string | 60s | How frequently to generate self-report metrics. This does utilize the global scrapeInterval setting. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-logs.alloy.mounts.dockercontainers | bool | `true` |  |
| alloy-logs.alloy.mounts.varlog | bool | `true` |  |
| alloy-metrics.alloy.clustering.enabled | bool | `true` |  |
| alloy-metrics.alloy.clustering.name | string | `"alloy-metrics"` |  |
| alloy-profiles.alloy.securityContext.privileged | bool | `true` |  |
| alloy-profiles.alloy.securityContext.runAsGroup | int | `0` |  |
| alloy-profiles.alloy.securityContext.runAsUser | int | `0` |  |
| alloy-profiles.alloy.stabilityLevel | string | `"public-preview"` |  |
| extraObjects | list | `[]` | Deploy additional manifest objects |
