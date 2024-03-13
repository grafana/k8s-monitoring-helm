# Structure

The Kubernetes Monitoring Helm chart contains many software packages and builds a comprehensive set of configuration and
secrets for those packages.
This document aims to describe and explain the structure of the Helm chart.

![Kubernetes Monitoring inside of a Cluster](https://grafana.com/media/docs/grafana-cloud/k8s/Helm-chart-agent-diagram.png)

## Software Deployed

This Helm chart deploys several packages to generate and capture the telemetry data on the cluster. This list
corresponds to the list of dependencies in this chart's Chart.yaml file. For each package, there is an associated
section inside the Helm chart's values.yaml file that controls how it is configured.

| Name                                                                                   | Type                      | Associated values             | Description                                                                                                                                                                                                          | 
|----------------------------------------------------------------------------------------|---------------------------|-------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Grafana Agent](https://grafana.com/oss/agent/)                                        | StatefulSet               | `grafana-agent`               | The Grafana Agent that is responsible for scraping metrics, and accepting metrics, logs, and traces via receivers                                                                                                    |
| Grafana Agent for Logs                                                                 | DaemonSet                 | `grafana-agent-logs`          | The Grafana Agent that gathers pod logs. By default, it uses HostPath volume mounts to read pod log files directly from the nodes. It can alternatively get logs via the API server and be deployed as a Deployment. |
| Grafana Agent for Events                                                               | Deployment                | `grafana-agent-events`        | The Grafana Agent that is responsible for gathering cluster events from the API server. This does not support clustering, so only one instance should be used.                                                       |
| [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)                 | Deployment                | `kube-state-metrics`          | A service for generating metrics about the state of the objects inside the cluster.                                                                                                                                  |
| [Node Exporter](https://github.com/prometheus/node_exporter)                           | DaemonSet                 | `prometheus-node-exporter`    | An exporter used for gathering hardware and OS metrics for *NIX nodes of the cluster.                                                                                                                                |
| [Windows Exporter](https://github.com/prometheus-community/windows_exporter)           | DaemonSet                 | `prometheus-windows-exporter` | An exporter used for gathering hardware and OS metrics for Windows nodes of the cluster. Not deployed by default.                                                                                                    |
| [OpenCost](https://www.opencost.io/)                                                   | Deployment                | `opencost`                    | Used for gathering cost metrics for the cluster.                                                                                                                                                                     |
| [Prometheus Operator CRDs](https://github.com/prometheus-operator/prometheus-operator) | CustomResourceDefinitions | `prometheus-operator-crds`    | The custom resources for the Prometheus Operator. This is used if you want to deploy PodMonitors, ServiceMonitors, or Probes.                                                                                        |

## Configuration Created

This Helm chart also creates the configuration files, stored in ConfigMaps for the Grafana Agent instances. These lists
describe the pieces of the configuration files and the section in the chart's values.yaml file that controls it.

### Grafana Agent Configuration

| Name                           | Associated values               | Description                                                                               |
|--------------------------------|---------------------------------|-------------------------------------------------------------------------------------------|
| Annotation-based Autodiscovery | `.metrics.autoDiscover`         | Controls how pods and services are automatically discovered, based on their annotations.  |
| Grafana Agent                  | `.metrics.agent`                | Controls how to scrape metrics from the Grafana Agents being deployed by this Helm chart. |
| kube-state-metrics             | `.metrics.kube-state-metrics`   |                                                                                           |
| Node Exporter                  | `.metrics.node-exporter`        |                                                                                           |
| Windows Exporter               | `.metrics.windows-exporter`     |                                                                                           |
| Kubelet                        |                                 |                                                                                           |
| cAdvisor                       |                                 |                                                                                           |
| API Server                     |                                 |                                                                                           |
| Kube Controller Manager        |                                 |                                                                                           |
| Kube Proxy                     |                                 |                                                                                           |
| Kube Scheduler                 |                                 |                                                                                           |
| Cost Metrics                   | `.metrics.cost`                 |                                                                                           |
| PodMonitor Objects             |                                 |                                                                                           |
| Probe Objects                  |                                 |                                                                                           |
| ServiceMonitor Objects         |                                 |                                                                                           |
| Kubernetes Monitoring          | `.metrics.kubernetesMonitoring` |                                                                                           |
| Filters for Received Metrics   | `.metrics.receiver.filters`     |                                                                                           |
| Filters for Received Traces    | `.traces.receiver.filters`      |                                                                                           |
| Processors for Received data   | `.receivers.processors`         |                                                                                           |
| Additional Configuration       | `.extraConfig`                  |                                                                                           |

### Grafana Agent for Logs Configuration

| Name            | Associated values      | Description |
|-----------------|------------------------|-------------|
| Pod Logs        | `.logs.pod_logs`       |             |
| PodLogs Objects | `.logs.podLogsObjects` |             |

### Grafana Agent for Events Configuration

| Name           | Associated values      | Description |
|----------------|------------------------|-------------|
| Cluster Events | `.logs.cluster_events` |             |

