<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring

![Version: 2.0.0-alpha.1](https://img.shields.io/badge/Version-2.0.0--alpha.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.0.0](https://img.shields.io/badge/AppVersion-2.0.0-informational?style=flat-square)

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

<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Collectors - Alloy Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-logs.controller.type | string | `"daemonset"` | The type of controller to use for the Alloy Logs instance. |
| alloy-logs.enabled | bool | `false` | Deploy the Alloy instance for collecting log data. |
| alloy-logs.extraConfig | string | `""` | Extra Alloy configuration to be added to the configuration file. |
| alloy-logs.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |
| alloy-logs.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| alloy-logs.logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Collectors - Alloy Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-metrics.controller.replicas | int | `1` | The number of replicas for the Alloy Metrics instance. |
| alloy-metrics.controller.type | string | `"statefulset"` | The type of controller to use for the Alloy Metrics instance. |
| alloy-metrics.enabled | bool | `false` | Deploy the Alloy instance for collecting metrics. |
| alloy-metrics.extraConfig | string | `""` | Extra Alloy configuration to be added to the configuration file. |
| alloy-metrics.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |
| alloy-metrics.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| alloy-metrics.logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Collectors - Alloy Profiles

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-profiles.controller.type | string | `"daemonset"` | The type of controller to use for the Alloy Profiles instance. |
| alloy-profiles.enabled | bool | `false` | Deploy the Alloy instance for gathering profiles. |
| alloy-profiles.extraConfig | string | `""` | Extra Alloy configuration to be added to the configuration file. |
| alloy-profiles.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |
| alloy-profiles.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| alloy-profiles.logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Collectors - Alloy Receiver

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-receiver.alloy.extraPorts | list | `[]` | The ports to expose for the Alloy receiver. |
| alloy-receiver.controller.type | string | `"daemonset"` | The type of controller to use for the Alloy Receiver instance. |
| alloy-receiver.enabled | bool | `false` | Deploy the Alloy instance for opening receivers to collect application data. |
| alloy-receiver.extraConfig | string | `""` | Extra Alloy configuration to be added to the configuration file. |
| alloy-receiver.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |
| alloy-receiver.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| alloy-receiver.logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Collectors - Alloy Singleton

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-singleton.controller.replicas | int | `1` | The number of replicas for the Alloy Singleton instance. This should remain a single instance to avoid duplicate data. |
| alloy-singleton.controller.type | string | `"deployment"` | The type of controller to use for the Alloy Singleton instance. |
| alloy-singleton.enabled | bool | `false` | Deploy the Alloy instance for data sources required to be deployed on a single replica. |
| alloy-singleton.extraConfig | string | `""` | Extra Alloy configuration to be added to the configuration file. |
| alloy-singleton.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |
| alloy-singleton.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| alloy-singleton.logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Features - Annotation Autodiscovery

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotationAutodiscovery | object | Disabled | Annotation Autodiscovery enables gathering metrics from Kubernetes Pods and Services discovered by special annotations. Requires a destination that supports metrics. To see the valid options, please see the [Annotation Autodiscovery feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-annotation-autodiscovery). |
| annotationAutodiscovery.destinations | list | `[]` | The destinations where cluster metrics will be sent. If empty, all metrics-capable destinations will be used. |
| annotationAutodiscovery.enabled | bool | `false` | Enable gathering metrics from Kubernetes Pods and Services discovered by special annotations. |

### Features - Application Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| applicationObservability | object | Disabled | Application Observability. Requires destinations that supports metrics, logs, and traces. To see the valid options, please see the [Application Observability feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-application-observability). |
| applicationObservability.destinations | list | `[]` | The destinations where application data will be sent. If empty, all capable destinations will be used. |
| applicationObservability.enabled | bool | `false` | Enable gathering Kubernetes Pod logs. |

### Cluster

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cluster.name | string | `""` | The name for this cluster. |

### Features - Cluster Events

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterEvents | object | Disabled | Cluster events. Requires a destination that supports logs. To see the valid options, please see the [Cluster Events feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-cluster-events). |
| clusterEvents.destinations | list | `[]` | The destinations where cluster events will be sent. If empty, all logs-capable destinations will be used. |
| clusterEvents.enabled | bool | `false` | Enable gathering Kubernetes Cluster events. |

### Features - Cluster Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterMetrics | object | Disabled | Cluster Monitoring enables observability and monitoring for your Kubernetes Cluster itself. Requires a destination that supports metrics. To see the valid options, please see the [Cluster Monitoring feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-cluster-metrics). |
| clusterMetrics.destinations | list | `[]` | The destinations where cluster metrics will be sent. If empty, all metrics-capable destinations will be used. |
| clusterMetrics.enabled | bool | `false` | Enable gathering Kubernetes Cluster metrics. |

### Destinations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| destinations | list | `[]` | The list of destinations where telemetry data will be sent. See the [destinations documentation](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/destinations/README.md) for more information. |

### Features - Frontend Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| frontendObservability | object | Disabled | Front-end Observability enables the Faro receiver for accepting traces and logs from front-end applications. Requires a destination that supports metrics, logs, and traces. To see the valid options, please see the [Front-end Observability feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-frontend-observability). |
| frontendObservability.destinations | list | `[]` | The destinations where cluster events will be sent. If empty, all traces and logs-capable destinations will be used. |
| frontendObservability.enabled | bool | `false` | Enable gathering front-end observability data. |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |

### Features - Service Integrations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| integrations | object | No integrations enabled | Service Integrations enables gathering telemetry data for common services and applications deployed to Kubernetes. To see the valid options, please see the [Service Integrations documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-integrations). |
| integrations.destinations | list | `[]` | The destinations where cluster events will be sent. If empty, all logs-capable destinations will be used. |
| integrations.enabled | bool | `true` | Enable Service Integrations. |

### Features - Pod Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| podLogs | object | Disabled | Pod logs. Requires a destination that supports logs. To see the valid options, please see the [Pod Logs feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-pod-logs). |
| podLogs.destinations | list | `[]` | The destinations where logs will be sent. If empty, all logs-capable destinations will be used. |
| podLogs.enabled | bool | `false` | Enable gathering Kubernetes Pod logs. |

### Features - Profiling

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| profiling | object | Disabled | Profiling enables gathering profiles from applications. Requires a destination that supports profiles. To see the valid options, please see the [Profiling feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-profiling). |
| profiling.destinations | list | `[]` | The destinations where profiles will be sent. If empty, all profiles-capable destinations will be used. |
| profiling.enabled | bool | `false` | Enable gathering profiles from applications. |

### Features - Prometheus Operator Objects

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| prometheusOperatorObjects | object | Disabled | Prometheus Operator Objects enables the gathering of metrics from objects like Probes, PodMonitors, and ServiceMonitors. Requires a destination that supports metrics. To see the valid options, please see the [Prometheus Operator Objects feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-prometheus-operator-objects). |
| prometheusOperatorObjects.destinations | list | `[]` | The destinations where metrics will be sent. If empty, all metrics-capable destinations will be used. |
| prometheusOperatorObjects.enabled | bool | `false` | Enable gathering metrics from Prometheus Operator Objects. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraObjects | list | `[]` | Deploy additional manifest objects |
