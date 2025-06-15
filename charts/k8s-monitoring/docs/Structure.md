# Structure

The Kubernetes Monitoring Helm chart contains many software packages, and builds a comprehensive set of configuration
and secrets for those packages.

![Kubernetes Monitoring inside of a Cluster](https://grafana.com/media/docs/grafana-cloud/k8s/helm-diagram-v3.png)

## Software deployed

This Helm chart deploys several packages to generate and capture the telemetry data on the cluster. This list
corresponds to the list of dependencies in this chart's Chart.yaml file. For each package, there is an associated
section inside the Helm chart's values.yaml file that controls how it is configured.

| Name                                                                                   | Type                      | Associated values             | Description                                                                                                                                                                                                               |
|----------------------------------------------------------------------------------------|---------------------------|-------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Grafana Alloy](https://grafana.com/oss/alloy/) for Metrics                            | StatefulSet               | `alloy-metrics`               | The Alloy instance responsible for scraping metrics, and accepting metrics, logs, and traces via receivers.                                                                                                               |
| Grafana Alloy Singleton                                                                | Deployment                | `alloy-singleton`             | The Alloy instance responsible for anything that must be done on a single instance, such as gathering Cluster events from the API server. This instance does not support clustering, so only one instance should be used. |
| Grafana Alloy for Logs                                                                 | DaemonSet                 | `alloy-logs`                  | The Alloy instance that gathers Pod logs. By default, it uses HostPath volume mounts to read Pod log files directly from the Nodes. It can alternatively get logs via the API server, and be deployed as a Deployment.    |
| Grafana Alloy for Application Data                                                     | DaemonSet                 | `alloy-receiver`              | The Alloy instance that opens receiver ports to process data delivered directly to Alloy (for example, applications instrumented with OpenTelemetry). SDKs                                                                |
| Grafana Alloy for Profiles                                                             | DaemonSet                 | `alloy-events`                | The Alloy instance responsible for gathering profiles.                                                                                                                                                                    |
| [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)                 | Deployment                | `kube-state-metrics`          | A service for generating metrics about the state of the objects inside the Cluster.                                                                                                                                       |
| [Node Exporter](https://github.com/prometheus/node_exporter)                           | DaemonSet                 | `prometheus-node-exporter`    | An exporter for gathering hardware and OS metrics for *NIX nodes of the Cluster.                                                                                                                                          |
| [Windows Exporter](https://github.com/prometheus-community/windows_exporter)           | DaemonSet                 | `prometheus-windows-exporter` | An exporter for gathering hardware and OS metrics for Windows nodes of the Cluster. Not deployed by default.                                                                                                              |
| [OpenCost](https://www.opencost.io/)                                                   | Deployment                | `opencost`                    | Used for gathering cost metrics for the Cluster.                                                                                                                                                                          |
| [Prometheus Operator CRDs](https://github.com/prometheus-operator/prometheus-operator) | CustomResourceDefinitions | `prometheus-operator-crds`    | The custom resources for the Prometheus Operator. Use if you want to deploy PodMonitors, ServiceMonitors, or Probes.                                                                                                      |
| [Grafana Beyla](https://grafana.com/oss/beyla-ebpf/)                                   | DaemonSet                 | `beyla`                       | Used for zero-code instrumentation of applications and gathering network metrics.                                                                                                                                         |
| [Kepler](https://sustainable-computing.io/)                                            | DaemonSet                 | `kepler`                      | Used for gathering energy consumption metrics.                                                                                                                                                                            |

### Grafana Alloy instances

There are multiple instances of Grafana Alloy instead of one instance that includes all functions. This design is
required for:

*   Balance between functionality and scalability
*   Security

#### Functionality/scalability balance

Without multiple instances, scalability can be hindered. For example, the default functionality of the Grafana Alloy for
Logs is to gather
logs via HostPath volume mounts.
This functionality requires the instance to be deployed as a DaemonSet.
The Grafana Alloy for Metrics is
deployed as a StatefulSet, which allows it to be scaled (optionally with a HorizontalPodAutoscaler) based on load.
Otherwise, it would lose its ability to scale.
The Grafana Alloy Singleton cannot be
scaled beyond one replica, because that would result in duplicate data being sent.

#### Security

Another reason for using distinct instances is to minimize the security footprint required. While the Alloy for Logs
may require a HostPath volume mount, the other instances do not.
That means they can be deployed with a more restrictive
security context.
This is similarly why we use a distinct Grafana Beyla and Node Exporter deployments to gather zero-code instrumented
data and Node metrics respectively, rather than using the
[beyla.ebpf](https://grafana.com/docs/alloy/latest/reference/components/beyla/beyla.ebpf/) or
[prometheus.exporter.unix](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.unix/)
Alloy components.
Separate instances allow Beyla and Node Exporter to be deployed with the permissions they require to gather their
data, while limiting Grafana Alloy to only act as a collector of that data.

## Configuration created

This Helm chart also creates the configuration files, stored in ConfigMaps, for the Grafana Alloy instances. The
configuration is built based on the features enabled in the values file and the collector they are assigned to. For
example, the Cluster Metrics feature is assigned to the Grafana Alloy for Metrics by default.

All configuration related to telemetry data destinations are automatically loaded onto the Grafana Alloy instances that
require them.

### Features

Here is the list of features, their section within the values file, and the default collector they are assigned to:

| Name                                                                                                                                                     | Associated values           | Default collector              | Description                                                                                                                                                                                 |
|----------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|--------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Cluster Metrics](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cluster-metrics)                         | `clusterMetrics`            | `alloy-metrics`                | Gathers metrics related the the Kubernetes Cluster itself.                                                                                                                                  |
| [Cluster Events](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cluster-events)                           | `clusterEvents`             | `alloy-singleton`              | Gathers Kubernetes lifecycle events as log data.                                                                                                                                            |
| [Node Logs](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-node-logs)                                     | `nodeLogs`                  | `alloy-logs`                   | Gathers logs from the Kubernetes Nodes.                                                                                                                                                     |
| [Pod Logs](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-pod-logs)                                       | `podLogs`                   | `alloy-logs`                   | Gathers logs from the Kubernetes Pods.                                                                                                                                                      |
| [Application Observability](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability)     | `applicationObservability`  | `alloy-receiver`               | Receives and processes application data from instrumented services.                                                                                                                         |
| [Auto Instrumentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-auto-instrumentation)               | `autoInstrumentation`       | `alloy-metrics`                | Deploys Grafana Beyla and gathers zero-code instrumented application metrics. If Application Observability is also enabled, zero-code instrumented application traces are captured as well. |
| [Annotation Autodiscovery](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-annotation-autodiscovery)       | `annotationAutodiscovery`   | `alloy-metrics`                | Automatically discovers and scrapes metrics from specially annotated Pods and Services.                                                                                                     |
| [Prometheus Operator Objects](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-prometheus-operator-objects) | `prometheusOperatorObjects` | `alloy-metrics`                | Discovers and scrapes metrics from Probes, PodMonitors, and ServiceMonitors.                                                                                                                |
| [Profiling](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-profiling)                                     | `profiling`                 | `alloy-profiles`               | Gathers application profiles from processes running within the Kubernetes Cluster.                                                                                                          |
| [Integrations](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-integrations)                               | `integrations`              | `alloy-metrics` & `alloy-logs` | Gathers metrics and logs from common services.                                                                                                                                              |

### Additional configuration sources

Each collector also has the ability to specify additional configuration sources. These are specified within the Alloy
instance's own section in the values file:

| Name                 | Associated values         | Description                                                                                                                                                                       |
|----------------------|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Extra configuration  | `alloy-___.extraConfig`   | Additional configuration to be added to the configuration file. Use this for adding custom configuration, but do not use it to modify existing configuration.                     |
| Remote configuration | `alloy-___.remoteConfig`  | Configuration for fetching remotely defined configuration. To configure, refer to [Grafana Fleet Management](https://grafana.com/docs/grafana-cloud/send-data/fleet-management/). |
| Logging              | `alloy-___.logging`       | Configuration for [logging](https://grafana.com/docs/alloy/latest/reference/config-blocks/logging/).                                                                              |
| Live debugging       | `alloy-___.liveDebugging` | Configuration for enabling the [Alloy Live Debugging feature](https://grafana.com/docs/alloy/latest/troubleshoot/debug/#live-debugging-page).                                     |
