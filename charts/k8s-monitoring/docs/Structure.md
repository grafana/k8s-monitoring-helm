# Structure

The Kubernetes Monitoring Helm chart contains many software packages, and builds a comprehensive set of configuration and
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
| Grafana Agent for Logs                                                                 | DaemonSet                 | `grafana-agent-logs`          | The Grafana Agent that gathers Pod logs. By default, it uses HostPath volume mounts to read Pod log files directly from the nodes. It can alternatively get logs via the API server and be deployed as a Deployment. |
| Grafana Agent for Events                                                               | Deployment                | `grafana-agent-events`        | The Grafana Agent that is responsible for gathering Cluster events from the API server. This does not support clustering, so only one instance should be used.                                                       |
| [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)                 | Deployment                | `kube-state-metrics`          | A service for generating metrics about the state of the objects inside the Cluster.                                                                                                                                  |
| [Node Exporter](https://github.com/prometheus/node_exporter)                           | DaemonSet                 | `prometheus-node-exporter`    | An exporter used for gathering hardware and OS metrics for *NIX nodes of the Cluster.                                                                                                                                |
| [Windows Exporter](https://github.com/prometheus-community/windows_exporter)           | DaemonSet                 | `prometheus-windows-exporter` | An exporter used for gathering hardware and OS metrics for Windows nodes of the Cluster. Not deployed by default.                                                                                                    |
| [OpenCost](https://www.opencost.io/)                                                   | Deployment                | `opencost`                    | Used for gathering cost metrics for the Cluster.                                                                                                                                                                     |
| [Prometheus Operator CRDs](https://github.com/prometheus-operator/prometheus-operator) | CustomResourceDefinitions | `prometheus-operator-crds`    | The custom resources for the Prometheus Operator. Use if you want to deploy PodMonitors, ServiceMonitors, or Probes.                                                                                        |

### Grafana Agent instances

You may wonder why there are three instances of the Grafana Agent, rather than combining them. The reason is a balance
between functionality and scalability. The default functionality of the Grafana Agent for Logs is to gather logs via
HostPath volume mounts. This requires it to be deployed as a DaemonSet. The Grafana Agent (for metrics and receivers) is
deployed as a StatefulSet, which allows it to be scaled (optionally with a HorizontalPodAutoscaler) based on load. If it
was combined with the Agent for Logs, it would lose its ability to scale.

Also, the Grafana Agent for Events cannot be scaled beyond one replica, because that would result in duplicate events
being sent to the logs service.

## Configuration Created

This Helm chart also creates the configuration files, stored in ConfigMaps, for the Grafana Agent instances. The
following lists describe the pieces of the configuration files and the section in the chart's values.yaml file that
controls it.

### Grafana Agent Configuration

| Name                           | Associated values                | Description                                                                                   |
|--------------------------------|----------------------------------|-----------------------------------------------------------------------------------------------|
| Annotation-based Autodiscovery | `.metrics.autoDiscover`          | Controls how Pods and services are automatically discovered, based on their annotations.      |
| Grafana Agent                  | `.metrics.agent`                 | Controls how to scrape metrics from the Grafana Agents being deployed by this Helm chart.     |
| kube-state-metrics             | `.metrics.kube-state-metrics`    | Controls how metrics from kube-state-metrics are discovered, scraped, and processed.          |
| Node Exporter                  | `.metrics.node-exporter`         | Controls how metrics from Node Exporter are discovered, scraped, and processed.               |
| Windows Exporter               | `.metrics.windows-exporter`      | Controls how metrics from Windows Exporter are discovered, scraped, and processed.            |
| Kubelet                        | `.metrics.kubelet`               | Controls how metrics from the Kubelet are discovered, scraped, and processed.                 |
| cAdvisor                       | `.metrics.cadvisor`              | Controls how metrics from cAdvisor are discovered, scraped, and processed.                    |
| API Server                     | `.metrics.apiserver`             | Controls how metrics from the API Server are discovered, scraped, and processed.              |
| Kube Controller Manager        | `.metrics.kubeControllerManager` | Controls how metrics from the Kube Controller Manager are discovered, scraped, and processed. |
| Kube Proxy                     | `.metrics.kubeProxy`             | Controls how metrics from the Kube Proxy are discovered, scraped, and processed.              |
| Kube Scheduler                 | `.metrics.kubeScheduler`         | Controls how metrics from the Kube Scheduler are discovered, scraped, and processed.          |
| Cost Metrics                   | `.metrics.cost`                  | Controls how cost metrics are discovered, scraped, and processed.                             |
| PodMonitor Objects             | `.metrics.podMonitors`           | Controls how PodMonitor objects are discovered, scraped, and processed.                       |
| Probe Objects                  | `.metrics.Probes`                | Controls how Probe objects are discovered, scraped, and processed.                            |
| ServiceMonitor Objects         | `.metrics.serviceMonitors`       | Controls how ServiceMonitor objects are discovered, scraped, and processed.                   |
| Kubernetes Monitoring          | `.metrics.kubernetesMonitoring`  | Enables or disables sending a static metric about how this Helm chart was deployed.           |
| Filters for Received Metrics   | `.metrics.receiver.filters`      | Allows for filtering rules on metrics being received via the receivers.                       |
| Filters for Received Logs      | `.logs.receiver.filters`         | Allows for filtering rules on logs being received via the receivers.                          |
| Filters for Received Traces    | `.traces.receiver.filters`       | Allows for filtering rules on traces being received via the receivers.                        |
| Processors for Received data   | `.receivers.processors`          | Configuration for processors on telemetry data being received via the receivers.              |
| Additional Configuration       | `.extraConfig`                   | Additional configuration to be added to the Grafana Agent.                                    |

### Grafana Agent for Logs Configuration

| Name                     | Associated values      | Description                                                         |
|--------------------------|------------------------|---------------------------------------------------------------------|
| Pod Logs                 | `.logs.pod_logs`       | Controls how Pod logs are gathered.                                 |
| PodLogs Objects          | `.logs.podLogsObjects` | Controls how PodLogs objects are discovered and processed.          |
| Additional Configuration | `.logs.extraConfig`    | Additional configuration to be added to the Grafana Agent for Logs. |

### Grafana Agent for Events Configuration

| Name           | Associated values      | Description                               |
|----------------|------------------------|-------------------------------------------|
| Cluster Events | `.logs.cluster_events` | Controls how cluster events are gathered. |

