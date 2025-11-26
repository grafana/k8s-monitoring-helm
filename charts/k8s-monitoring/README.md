<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring

![Version: 3.6.1](https://img.shields.io/badge/Version-3.6.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.6.1](https://img.shields.io/badge/AppVersion-3.6.1-informational?style=flat-square)
Capture all telemetry data from your Kubernetes cluster.

## Breaking change announcements

### Version 3.4

<!--alex disable hook-->
<!--alex disable hooks-->
#### Alloy no longer deployed by hooks

Version 3.3 deployed the Alloy instances during a post-install Helm hook. This cause problems where Alloy instances
were not handle properly when running upgrades or when using deployment tools like ArgoCD.

When upgrading to v3.4 or later, the Alloy resources will no longer be deployed by Helm hooks, but the upgrade may fail
with this message:

```text
Error: UPGRADE FAILED: Unable to continue with update: Alloy "k8smon-alloy-metrics" in namespace "default" exists and cannot be imported into the current release: invalid ownership metadata; label validation error: missing key "app.kubernetes.io/managed-by": must be set to "Helm"; annotation validation error: missing key "meta.helm.sh/release-name": must be set to "k8smon"; annotation validation error: missing key "meta.helm.sh/release-namespace": must be set to "default"
```

To resolve this, when you run the upgrade, use the `--take-ownership` flag which will update the Alloy resources to be
properly managed by Helm again.

### Version 3.0

#### Alloy Operator

v3.0 introduces the use of the [Alloy Operator](https://github.com/grafana/alloy-operator) to manage the creation and
lifecycle of Alloy instances. When upgrading from v2.0 to v3.0 or later, you may need to install the Alloy CRD.

To do this, run the following command:

```shell
kubectl apply -f https://github.com/grafana/alloy-operator/releases/latest/download/collectors.grafana.com_alloy.yaml
```

#### Pod Logs

v3.0 also moves the `pod` and `k8s.pod.name` fields from labels to structured metadata in the pod logs feature. If your
logs destination does not support structured metadata, you may not see these labels on your logs.

### Version 2.1

Version 2.1 was re-versioned to be 3.0. If you are on 2.1, please upgrade to 3.0.

### Version 2.0

v2 introduces some significant changes to the chart configuration values. Refer to the migration [documentation](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/migrate-helm-chart/) for tools and strategies to migrate from v1.

## Usage

### Setup Grafana chart repository

```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Build your values

There are some required values that will need to be used with this chart. The basic structure of the values file is:

```yaml
cluster: # Cluster configuration, including the cluster name
  name: my-cluster

destinations: [...] # List of destinations where telemetry data will be sent

# Features to enable, which determines what data to collect
clusterMetrics:
  enabled: true
clusterEvents:
  enabled: true
# etc...
...

# Telemetry collector definitions
alloy-metrics:
  enabled: true
alloy-singleton:
  enabled: true
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

Alternatively, you may also define a map of destinations. The key for each destination in the map will be used as the name.

```yaml
destinationsMap:
  hostedMetrics:
    type: prometheus
    url: https://prometheus.example.com/api/prom/push
    auth:
      type: basic
      username: "my-username"
      password: "my-password"
  localPrometheus:
    type: prometheus
    url: http://prometheus.monitoring.svc.cluster.local:9090
  hostedLogs:
    type: loki
    url: https://loki.example.com/loki/api/v1/push
    auth:
      type: basic
      username: "my-username"
      password: "my-password"
      tenantIdFrom: env("LOKI_TENANT_ID")
```

#### Collectors

([Documentation](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/collector-reference/))

Collectors are workloads that are dedicated to gathering metrics, logs, traces, and profiles from the cluster and
from workloads on the cluster. There are multiple collector instances to optimize around the collection requirements.

The list of collectors are:

*   **alloy-metrics** is a StatefulSet that scrapes metrics from sources like cAdvisor, Kubelet, and kube-state-metrics.
*   **alloy-logs** is the logs collector. It is deployed as a DaemonSet and gathers Pod and Node logs.
*   **alloy-receiver** is a DaemonSet to collect telemetry data sent via HTTP, gRPC, Zipkin, etc...
*   **alloy-singleton** is a 1-replica Deployment to collect cluster events.
*   **alloy-profiles** is a DaemonSet used to instrument and collect profiling data.

To enable a collector, add a new section to your values file. Example:

```YAML
alloy-{collector_name}:
  enabled: true
```

**Specific features require specific collector configuration**. For example, the applicationObservability feature requires the alloy-receiver, with specific ports open for select protocols. Check [individual feature documentation](./docs/Features.md) to find out about collector requirements.

#### Features

([Documentation](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/#features))

This section is where you define which features you want to enable with this chart. Features define what kind of data to collect.

Here is an example of enabling some features:

```yaml
clusterMetrics:
  enabled: true

clusterEvents:
  enabled: true

podLogs:
  enabled: true
```

## Compatibility

The Kubernetes Monitoring Helm chart is designed to be compatible with all supported Kubernetes Cluster versions. It
deploys several dependent systems, which may have their own compatibility matrices. See their documentation for more
details:

| System             | Feature in k8s-monitoring | Link to documentation                                                                          |
|--------------------|---------------------------|------------------------------------------------------------------------------------------------|
| Alloy              | all                       | No published compatibility matrix                                                              |
| Alloy Operator     | all                       | No published compatibility matrix                                                              |
| Beyla              | `autoInstrumentation`     | No published compatibility matrix                                                              |
| Kepler             | `clusterMetrics`          | No published compatibility matrix                                                              |
| kube-state-metrics | `clusterMetrics`          | [Compatibility Matrix](https://github.com/kubernetes/kube-state-metrics#compatibility-matrix)] |
| Node Exporter      | `clusterMetrics`          | No published compatibility matrix                                                              |
| OpenCost           | `clusterMetrics`          | No published compatibility matrix                                                              |
| Windows Exporter   | `clusterMetrics`          | No published compatibility matrix                                                              |

<!-- textlint-disable terminology -->
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
| rlankfo | <robert.lankford@grafana.com> |  |
<!-- textlint-enable terminology -->

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
|  | podLogsViaKubernetesApi(feature-pod-logs-via-kubernetes-api) | 1.0.0 |
|  | profilesReceiver(feature-profiles-receiver) | 1.0.0 |
|  | profiling(feature-profiling) | 1.0.0 |
|  | prometheusOperatorObjects(feature-prometheus-operator-objects) | 1.0.0 |
| https://grafana.github.io/helm-charts | alloy-operator | 0.3.12 |
<!-- markdownlint-enable no-bare-urls -->

## Values

### Collectors - Alloy Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-logs.enabled | bool | `false` | Deploy the Alloy instance for collecting log data. |

### Collectors - Alloy Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-metrics.enabled | bool | `false` | Deploy the Alloy instance for collecting metrics. |

### Alloy Operator

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-operator.deploy | bool | `true` | Deploy the Alloy Operator. |
| alloy-operator.waitForAlloyRemoval.enabled | bool | `true` | Utilize a Helm Hook to wait for all Alloy instances to be removed before uninstalling the Alloy Operator. This ensures that all Alloy instances are properly cleaned up before the operator is removed. |
| alloy-operator.waitForAlloyRemoval.image | object | `{"digest":"","pullPolicy":"IfNotPresent","pullSecrets":[],"registry":"ghcr.io","repository":"grafana/helm-chart-toolbox-kubectl","tag":"0.1.2"}` | The image to use for the Helm Hook that ensures that Alloy instances are removed during uninstall. |
| alloy-operator.waitForAlloyRemoval.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | Node selector to use for the Helm Hook that ensures that Alloy instances are removed during uninstall. |
| alloy-operator.waitForAlloyRemoval.podAnnotations | object | `{}` | Annotations to apply to the Pod for the Helm Hook to wait for all Alloy instances to be removed before uninstalling the Alloy Operator |
| alloy-operator.waitForAlloyRemoval.podLabels | object | `{"linkerd.io/inject":"disabled","sidecar.istio.io/inject":"false"}` | Labels to apply to the Pod for the Helm Hook to wait for all Alloy instances to be removed before uninstalling the Alloy Operator |
| alloy-operator.waitForAlloyRemoval.resources | object | `{}` | Set the resource field for the Helm Hook that ensures that Alloy instances are removed during uninstall. |
| alloy-operator.waitForAlloyRemoval.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"runAsUser":4242,"seccompProfile":{"type":"RuntimeDefault"}}` | Default security context to apply to the container. This can also be set to `null` to remove the security context entirely. Also, `runAsUser` can be set to `null` to remove it. |
| alloy-operator.waitForAlloyRemoval.tolerations | list | `[]` | Tolerations to apply to the Helm Hook that ensures that Alloy instances are removed during uninstall. |

### Collectors - Alloy Profiles

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-profiles.enabled | bool | `false` | Deploy the Alloy instance for gathering profiles. |

### Collectors - Alloy Receiver

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-receiver.alloy.extraPorts | list | `[]` | The ports to expose for the Alloy receiver. |
| alloy-receiver.enabled | bool | `false` | Deploy the Alloy instance for opening receivers to collect application data. |
| alloy-receiver.extraService.enabled | bool | `false` | Create an extra service for the Alloy receiver. This service will mirror the alloy-receiver service, but its name can be customized to match existing application settings. |
| alloy-receiver.extraService.fullname | string | `""` | If set, the full name of the extra service to create. This will result in the format `<fullname>`. |
| alloy-receiver.extraService.name | string | `"alloy"` | The name of the extra service to create. This will result in the format `<release-name>-<name>`. |

### Collectors - Alloy Singleton

| Key | Type | Default | Description |
|-----|------|---------|-------------|
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
| applicationObservability.enabled | bool | `false` | Enable receiving Application Observability. |
| applicationObservability.receivers | object | `{}` | The receivers used for receiving application data. |

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

### Collectors - Common

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| collectorCommon.alloy | object | `{}` | Settings to apply to all Alloy instances created by this Helm chart. This includes Alloy instances created by enabling Tail Sampling or Service Graph Metrics. |

### Destinations

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| destinations | list | `[]` | The list of destinations where telemetry data will be sent. See the [destinations documentation](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/destinations/README.md) for more information. |
| destinationsMap | object | `{}` | A map of destinations where telemetry data will be sent. Keys will be used as the destination name. See the [destinations documentation](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/destinations/README.md) for more information. |

### Extra Objects

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraObjects | list | `[]` | Deploy additional manifest objects |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.kubernetesAPIService | string | `""` | The Kubernetes service. Change this if your cluster DNS is configured differently than the default. |
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |
| global.scrapeClassicHistograms | bool | `false` | Whether to scrape a classic histogram that’s also exposed as a native histogram. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |
| global.scrapeNativeHistograms | bool | `false` | Whether to scrape native histograms. |
| global.scrapeProtocols | list | `["OpenMetricsText1.0.0","OpenMetricsText0.0.1","PrometheusText0.0.4"]` | The protocols to negotiate during a Prometheus metrics scrape, in order of preference. |
| global.scrapeTimeout | string | `"10s"` | The timeout for scraping metrics. |

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

### Features - Pod Logs via Kubernetes API

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| podLogsViaKubernetesApi | object | Disabled | Pod logs via Kubernetes API. Requires a destination that supports logs. To see the valid options, please see the [Pod Logs via Kubernetes API feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-pod-logs-via-kubernetes-api). |
| podLogsViaKubernetesApi.destinations | list | `[]` | The destinations where logs will be sent. If empty, all logs-capable destinations will be used. |
| podLogsViaKubernetesApi.enabled | bool | `false` | Enable gathering Kubernetes Pod logs. |

### Features - Profiles Receiver

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| profilesReceiver | object | Disabled | Profiles Receiver enables receiving profiles from applications. Requires a destination that supports profiles. To see the valid options, please see the [Profiles Receiver feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-profiles-receiver). |
| profilesReceiver.destinations | list | `[]` | The destinations where profiles will be sent. If empty, all profiles-capable destinations will be used. |
| profilesReceiver.enabled | bool | `false` | Enable gathering profiles from applications. |

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
