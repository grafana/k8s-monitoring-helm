# Migration guide

## Migrating from version 1.x to 2.0

The 2.0 release of the k8s-monitoring Helm chart includes major changes from the 1.x version. Many of the features have
been re-arranged to be organized around features, rather than data types (e.g. metrics, logs, etc.). This document will
explain how the settings have changed, feature-by-feature, and how to migrate your v1 values.yaml file.

In v1, many features were enabled by default. Cluster metrics, pod logs, cluster events, etc... In v2, all features
are disabled by default, which leads your values file to better reflect your desired feature set.

A migration tool is available
at [https://grafana.github.io/k8s-monitoring-helm-migrator/](https://grafana.github.io/k8s-monitoring-helm-migrator/).

### Destinations

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

#### Steps to take

1.  Create a destination for each external service you are using.
2.  Provide a `name` and a `type` for the destination
3.  Provide the URL for the destination. *NOTE* this is a full data writing/pushing URL, not just the hostname!
4.  Map the other settings from the original service to the new destination

-   `authMode` --> `auth.type`
-   Auth definitions (e.g. `basicAuth`) --> `auth`
-   `externalLabels` --> `extraLabels`
-   `writeRelabelRules` --> `metricProcessingRules`

### Collectors

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

#### Steps to take

1.  Rename `alloy` to `alloy-metrics`
2.  Rename `alloy-events` to `alloy-singleton`
3.  Move any open receiver ports to the `alloy-receiver` instance

### Cluster Events

Gathering of Cluster Events has been moved into its own feature called `clusterEvents`.

| Feature        | v1.x setting          | v2.0 setting    | Notes |
|----------------|-----------------------|-----------------|-------|
| Cluster Events | `logs.cluster_events` | `clusterEvents` |       |

#### Steps to take

If using cluster events, `logs.cluster_events.enabled`:

1.  Enable `clusterEvents` and `alloy-singleton` in your values file:

    ```yaml
    clusterEvents:
      enabled: true
    alloy-singleton:
      enabled: true
    ```

2.  Move `logs.cluster_events` to `clusterEvents`
3.  Rename `extraStageBlocks` to `extraProcessingStages`

### Cluster Metrics

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

#### Steps to take

If using cluster metrics, `metrics.enabled`:

1.  Enable `clusterMetrics` and `alloy-metrics` in your values file:

    ```yaml
    clusterMetrics:
      enabled: true
    alloy-metrics:
      enabled: true
    ```

2.  Move each of the sections in the above table to `clusterMetrics`
3.  Rename any `extraRelabelingRules` to `extraDiscoveryRules`
4.  Rename any `extraMetricRelabelingRules` to `extraMetricProcessingRules`

### Annotation Auto-discovery

Discovery of pods and services by annotation has been moved into its own feature called `annotationAutodiscovery`.

| Feature                   | v1.x setting           | v2.0 setting              | Notes |
|---------------------------|------------------------|---------------------------|-------|
| Annotation auto-discovery | `metrics.autoDiscover` | `annotationAutodiscovery` |       |

#### Steps to take

If using annotation auto-discovery, `metrics.autoDiscover.enabled`:

1.  Enable `annotationAutodiscovery` and `alloy-metrics` in your values file:

    ```yaml
    annotationAutodiscovery:
      enabled: true
    alloy-metrics:
      enabled: true
    ```

2.  Move the contents of `metrics.autoDiscover` to `annotationAutodiscovery`
3.  Rename any `extraRelabelingRules` to `extraDiscoveryRules`
4.  Rename any `extraMetricRelabelingRules` to `extraMetricProcessingRules`

### Application Observability

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

#### Steps to take

If using application observability, `traces.enabled`, `receivers.*.enabled`:

1.  Enable `applicationObservability` and `alloy-receiver` in your values file:

    ```yaml
    applicationObservability:
      enabled: true
    alloy-receiver:
      enabled: true
    ```

2.  Move any extra ports opened for applications from `alloy.alloy.extraPorts` to `alloy-receiver.alloy.extraPorts`
3.  Enable the receivers you want to use in `applicationObservability.receivers`, for example:

    ```yaml
    applicationObservability:
      receivers:
        grpc:
          enabled: true
    ```

4.  Move receiver processors from `receivers.processors` to `applicationObservability.processors`
5.  Move metric filters from `metrics.receiver.filters` to `applicationObservability.metrics.filters`
6.  Move metric transforms from `metrics.receiver.transforms` to `applicationObservability.metrics.transforms`
7.  Move log filters from `logs.receiver.filters` to `applicationObservability.logs.filters`
8.  Move log transforms from `logs.receiver.transforms` to `applicationObservability.logs.transforms`
9.  Move trace filters from `traces.receiver.filters` to `applicationObservability.traces.filters`
10.  Move trace transforms from `traces.receiver.transforms` to `applicationObservability.traces.transforms`

### Auto-Instrumentation (Grafana Beyla)

Deployment and handling of the auto instrumentation feature, using Grafana Beyla, has been moved into its own feature
called `autoInstrumentation`.

| Feature                      | v1.x setting    | v2.0 setting                | Notes |
|------------------------------|-----------------|-----------------------------|-------|
| Auto-instrumentation metrics | `metrics.beyla` | `autoInstrumentation.beyla` |       |
| Beyla deployment             | `beyla`         | `autoInstrumentation.beyla` |       |

#### Steps to take

If using Beyla, `beyla.enabled`:

1.  Enable `autoInstrumentation` and `alloy-metrics` in your values file:

    ```yaml
    autoInstrumentation:
      enabled: true
    alloy-metrics:
      enabled: true
    ```

2.  Combine `beyla` and `metrics.beyla` and copy to `autoInstrumentation.beyla`

### Pod Logs

Gathering of pods logs has been moved into its own feature called `podLogs`.

| Feature  | v1.x setting    | v2.0 setting | Notes |
|----------|-----------------|--------------|-------|
| Pod Logs | `logs.pod_logs` | `podLogs`    |       |

#### Steps to take

If using pod logs, `logs.pod_logs.enabled`:

1.  Enable `podLogs` and `alloy-logs` in your values file:

    ```yaml
    podLogs:
      enabled: true
    alloy-logs:
      enabled: true
    ```

2.  Move `logs.pod_logs` to `podLogs`
3.  Rename any `extraRelabelingRules` to `extraDiscoveryRules`
4.  Rename any `extraStageBlocks` to `extraLogProcessingStages`

### Prometheus Operator Objects

Handling for Prometheus Operator objects, such as `ServiceMonitors`, `PodMonitors`, and `Probes` has been moved to the
`prometheusOperatorObjects` feature. This feature also includes the option to deploy the Prometheus Operator CRDs.

| Feature                 | v1.x setting                       | v2.0 setting                                | Notes |
|-------------------------|------------------------------------|---------------------------------------------|-------|
| PodMonitor settings     | `metrics.podMonitors`              | `prometheusOperatorObjects.podMonitors`     |       |
| Probe settings          | `metrics.probes`                   | `prometheusOperatorObjects.probes`          |       |
| ServiceMonitor settings | `metrics.serviceMonitors`          | `prometheusOperatorObjects.serviceMonitors` |       |
| CRDs deployment         | `prometheus-operator-crds.enabled` | `crds.deploy`                               |       |

#### Steps to take

If using Prometheus Operator objects, `metrics.podMonitors.enabled`, `metrics.probes.enabled`,
`metrics.serviceMonitors.enabled`, `prometheus-operator-crds.enabled`:

1.  Enable `prometheusOperatorObjects` and `alloy-metrics` in your values file:

    ```yaml
    prometheusOperatorObjects:
     enabled: true
    alloy-metrics:
     enabled: true
    ```

2.  Move `metrics.podMonitors` to `prometheusOperatorObjects.podMonitors`
3.  Move `metrics.probes` to `prometheusOperatorObjects.probes`
4.  Move `metrics.serviceMonitors` to `prometheusOperatorObjects.serviceMonitors`

### Integrations

Integrations are a new feature in v2.0 that allow you to enable and configure additional data sources, but this also
includes the Alloy metrics that were previously part of `v1`.

| Integration  | v1.x setting                       | v2.0 setting                | Notes |
|--------------|------------------------------------|-----------------------------|-------|
| Alloy        | `metrics.alloy`                    | `integrations.alloy`        |       |
| cert-manager | `extraConfig`                      | `integrations.cert-manager` |       |
| etcd         | `extraConfig`                      | `integrations.etcd`         |       |
| MySQL        | `extraConfig` & `logs.extraConfig` | `integrations.mysql`        |       |

#### Steps to take

If using the Alloy integration `metrics.alloy.enabled`, or if using `extraConfig` for cert-manager, etcd, or MySQL:

1.  Create instances of the integration that you want and enable `alloy-metrics` in your values file:

    ```yaml
    integrations:
     alloy:
       instances:
       - name: "alloy"
    alloy-metrics:
     enabled: true
    ```

2.  Move `metrics.alloy` to `integrations.alloy.instances[]`

### Extra Configs

The variables for adding arbitrary configuration to the Alloy instances has been moved inside the respective Alloy
instance.

| extraConfig        | v1.x setting                       | v2.0 setting                | Notes |
|--------------------|------------------------------------|-----------------------------|-------|
| Alloy              | `metrics.alloy`                    | `integrations.alloy`        |       |
| Alloy Events       | `extraConfig`                      | `integrations.cert-manager` |       |
| Alloy Logs         | `extraConfig`                      | `integrations.etcd`         |       |
| Alloy for Profiles | `extraConfig` & `logs.extraConfig` | `integrations.mysql`        |       |

#### Steps to take

1.  Move `extraConfig` related to metrics to `alloy-metrics.extraConfig`
2.  Move `extraConfig` related to application receivers to `alloy-receivers.extraConfig`
3.  Move `logs.cluster_events.extraConfig` to `alloy-singleton.extraConfig`
4.  Move `logs.extraConfig` to `alloy-logs.extraConfig`
5.  Move `profiles.extraConfig` to `alloy-profiles.extraConfig`

### Dropped features

The following features have been removed from the 2.0 release:

-   **Pre-install hooks**: The pre-install and pre-upgrade hooks that did config validation have been removed. The Alloy
    pods will now validate the configuration at runtime and log any issues and without these pods, this greatly
    decreases startup time.
-   **`helm test` functionality**: The `helm test` functionality that ran a config analysis and attempted to query the
    databases for expected metrics and logs has been removed. This functionality was either not fully developed, or not
    useful in production environments. The query testing was mainly for CI/CD testing in development and has been
    replaced by more effective and comprehensive methods.
