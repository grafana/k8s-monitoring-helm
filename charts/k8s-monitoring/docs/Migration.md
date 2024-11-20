# Migration guide

## Migrating from version 1.x to 2.0

The 2.0 release of the k8s-monitoring Helm chart includes major changes from the 1.x version. Many of the features have
been re-arranged to be organized around features, rather than data types (e.g. metrics, logs, etc.). This document will
explain how the settings have changed, feature-by-feature, and how to migrate your v1 values.yaml file.

In v1, many features were enabled by default. Cluster metrics, pod logs, cluster events, etc... In v2, all features
are disabled by default, which leads your values file to better reflect your desired feature set.

A migration tool is available at [https://grafana.github.io/k8s-monitoring-helm-migrator/](https://grafana.github.io/k8s-monitoring-helm-migrator/).

### Changes by feature

#### Destinations

The definition of where data is delivered has changed from `externalServices`, an object of four types, to
`destinations`, an array of any number of types. Before the `externalServices` object had four types of destinations:

-   `prometheus` - Where all metrics are delivered. It could refer to a true Prometheus server, or an OTLP destination
    that handles metrics.
-   `loki` - Where all logs are delivered. It could refer to a true Loki server, or an OTLP destination that handles logs.
-   `tempo` - Where all traces are delivered. It could refer to a true Tempo server, or an OTLP destination that handles
    traces.
-   `pyroscope` - Where all profiles are delivered.

So, the service essentially referred to the destination for the data type. In v2, the destination refers to the protocol
used to deliver the data type.

See [Destinations](destinations/README.md) for more information.

Here's how to map from v1 `externalServices` to v2 `destinations`:

| Service           | v1.x setting                  | v2.0 setting                                               |
|-------------------|-------------------------------|------------------------------------------------------------|
| Prometheus        | `externalServices.prometheus` | `destinations: [{type: "prometheus"}]`                     |
| Prometheus (OTLP) | `externalServices.prometheus` | `destinations: [{type: "otlp", metrics: {enabled: true}}]` |
| Loki              | `externalServices.loki`       | `destinations: [{type: "loki"}]`                           |
| Loki (OTLP)       | `externalServices.loki`       | `destinations: [{type: "loki", logs: {enabled: true}}]`    |
| Tempo             | `externalServices.tempo`      | `destinations: [{type: "otlp"}]`                           |
| Pyroscope         | `externalServices.pyroscope`  | `destinations: [{type: "pyroscope"}]`                      |

#### Collectors

The Alloy instances has been further split from the original to allow for more flexibility in the configuration and
predictability in their resource requirements. Each feature allows for setting the collector, but the defaults have been
chosen carefully, so you should only need to change these if you have specific requirements.

| Responsibility        | v1.x Alloy       | v2.0 Alloy        | Notes                                                                           |
|-----------------------|------------------|-------------------|---------------------------------------------------------------------------------|
| Metrics               | `alloy`          | `alloy-metrics`   |                                                                                 |
| Logs                  | `alloy-logs`     | `alloy-logs`      |                                                                                 |
| Cluster events        | `alloy-events`   | `alloy-singleton` | This is also for anything else that must only be deployed to a single instance. |
| Application receivers | `alloy`          | `alloy-receiver`  |                                                                                 |
| Profiles              | `alloy-profiles` | `alloy-profiles`  |                                                                                 |

#### Cluster Events

Gathering of pods logs has been moved into its own feature called `podLogs`.

| Feature  | v1.x setting    | v2.0 setting | Notes |
|----------|-----------------|--------------|-------|
| Pod Logs | `logs.pod_logs` | `podLogs`    |       |

#### Cluster Metrics

Cluster metrics refers to any metric data source that scrapes metrics about the cluster itself. This includes the
following data sources:

-   Cluster metrics (Kubelet, API Server, etc.)
-   Node metrics (Node Exporter & Windows Exporter)
-   kube-state-metrics
-   Energy metrics via Kepler
-   Cost metrics via OpenCost

These have all been combined into a single feature called `clusterMetrics`.

| Feature                       | v1.x setting                  | v2.0 setting                        | Notes                                                                              |
|-------------------------------|-------------------------------|-------------------------------------|------------------------------------------------------------------------------------|
| Kubelet metrics               | `metrics.kubelet`             | `clusterMetrics.kubelet`            |                                                                                    |
| cAdvisor metrics              | `metrics.cadvisor`            | `clusterMetrics.cadvisor`           |                                                                                    |
| kube-state-metrics metrics    | `metrics.cadvisor`            | `clusterMetrics.kube-state-metrics` |                                                                                    |
| kube-state-metrics deployment | `kube-state-metrics`          | `clusterMetrics.kube-state-metrics` | The decision to deploy is controlled by `clusterMetrics.kube-state-metrics.deploy` |
| Node Exporter metrics         | `metrics.node-exporter`       | `clusterMetrics.node-exporter`      |                                                                                    |
| Node Exporter deployment      | `prometheus-node-exporter`    | `clusterMetrics.node-exporter`      | The decision to deploy is controlled by `clusterMetrics.node-exporter.deploy`      |
| Windows Exporter metrics      | `metrics.windows-exporter`    | `clusterMetrics.windows-exporter`   |                                                                                    |
| Windows Exporter deployment   | `prometheus-windows-exporter` | `clusterMetrics.windows-exporter`   | The decision to deploy is controlled by `clusterMetrics.windows-exporter.deploy`   |
| Energy metrics (Kepler)       | `metrics.kepler`              | `clusterMetrics.kepler`             |                                                                                    |
| Kepler deployment             | `kepler`                      | `clusterMetrics.kepler`             |                                                                                    |
| Cost metrics (OpenCost)       | `metrics.opencost`            | `clusterMetrics.opencost`           |                                                                                    |
| OpenCost deployment           | `opencost`                    | `clusterMetrics.opencost`           |                                                                                    |

#### Annotation Auto-discovery

Discovery of pods and services by annotation has been moved into its own feature called `annotationAutodiscovery`.

| Feature                   | v1.x setting           | v2.0 setting              | Notes |
|---------------------------|------------------------|---------------------------|-------|
| Annotation auto-discovery | `metrics.autoDiscover` | `annotationAutodiscovery` |       |

#### Application Observability

Application Observability is the new name for the feature that encompasses receiving data via various receivers (e.g.
OTLP, Zipkin, etc...), processing that data, and delivering it to the destinations. Previously, this was mostly handled
within the metrics, logs, and traces sections, but has been moved into its own feature.

| Feature              | v1.x setting                  | v2.0 setting                                  | Notes |
|----------------------|-------------------------------|-----------------------------------------------|-------|
| Collector ports      | `alloy.alloy.extraPorts`      | `alloy-receiver.alloy.extraPorts`             |       |
| Receiver definitions | `receivers`                   | `applicationObservability.receivers`          |       |
| Processors           | `receivers.processors`        | `applicationObservability.processors`         |       |
| Metric Filters       | `metrics.receiver.filters`    | `applicationObservability.metrics.filters`    |       |
| Metric Transforms    | `metrics.receiver.transforms` | `applicationObservability.metrics.transforms` |       |
| Log Filters          | `logs.receiver.filters`       | `applicationObservability.logs.filters`       |       |
| Log Transforms       | `logs.receiver.transforms`    | `applicationObservability.logs.transforms`    |       |
| Trace Filters        | `traces.receiver.filters`     | `applicationObservability.traces.filters`     |       |
| Trace Transforms     | `traces.receiver.transforms`  | `applicationObservability.traces.transforms`  |       |

#### Auto-Instrumentation (Grafana Beyla)

Deployment and handling of the auto instrumentation feature, using Grafana Beyla, has been moved into its own feature
called `autoInstrumentation`.

| Feature                      | v1.x setting    | v2.0 setting                | Notes |
|------------------------------|-----------------|-----------------------------|-------|
| Auto-instrumentation metrics | `metrics.beyla` | `autoInstrumentation.beyla` |       |
| Beyla deployment             | `beyla`         | `autoInstrumentation.beyla` |       |

#### Pod Logs

Deployment and handling of the auto instrumentation feature, using Grafana Beyla, has been moved into its own feature
called `autoInstrumentation`.

#### Prometheus Operator Objects

Handling for Prometheus Operator objects, such as `ServiceMonitors`, `PodMonitors`, and `Probes` has been moved to the
`prometheusOperatorObjects` feature. This feature also includes the option to deploy the Prometheus Operator CRDs.

| Feature                 | v1.x setting                       | v2.0 setting                                | Notes |
|-------------------------|------------------------------------|---------------------------------------------|-------|
| PodMonitor settings     | `metrics.podMonitors`              | `prometheusOperatorObjects.podMonitors`     |       |
| Probe settings          | `metrics.probes`                   | `prometheusOperatorObjects.probes`          |       |
| ServiceMonitor settings | `metrics.serviceMonitors`          | `prometheusOperatorObjects.serviceMonitors` |       |
| CRDs deployment         | `prometheus-operator-crds.enabled` | `crds.deploy`                               |       |

#### Integrations

Integrations are a new feature in v2.0 that allow you to enable and configure additional data sources, but this also
includes the Alloy metrics that were previously part of `v1`.

| Integration             | v1.x setting                       | v2.0 setting                | Notes |
|-------------------------|------------------------------------|-----------------------------|-------|
| Alloy                   | `metrics.alloy`                    | `integrations.alloy`        |       |
| cert-manager            | `extraConfig`                      | `integrations.cert-manager` |       |
| etcd                    | `extraConfig`                      | `integrations.etcd`         |       |
| ServiceMonitor settings | `extraConfig` & `logs.extraConfig` | `integrations.mysql`        |       |

#### Extra Configs

The variables for adding arbitrary configuration to the Alloy instances has been moved inside the respective Alloy
instance.

| extraConfig        | v1.x setting                       | v2.0 setting                | Notes |
|--------------------|------------------------------------|-----------------------------|-------|
| Alloy              | `metrics.alloy`                    | `integrations.alloy`        |       |
| Alloy Events       | `extraConfig`                      | `integrations.cert-manager` |       |
| Alloy Logs         | `extraConfig`                      | `integrations.etcd`         |       |
| Alloy for Profiles | `extraConfig` & `logs.extraConfig` | `integrations.mysql`        |       |

### Dropped features

The following features have been removed from the 2.0 release:

-   **Pre-install hooks**: The pre-install and pre-upgrade hooks that did config validation have been removed. The Alloy
    pods will now validate the configuration at runtime and log any issues and without these pods, this greatly
    increases startup time.
-   **`helm test` functionality**: The `helm test` functionality that ran a config analysis and attempted to query the
    databases for expected metrics and logs has been removed. This functionality was either not fully developed, or not
    useful in production environments. The query testing was mainly for CI/CD testing in development and has been
    replaced by more effective and comprehensive methods.
