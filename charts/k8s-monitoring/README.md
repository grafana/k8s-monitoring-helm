# k8s-monitoring

![Version: 0.1.13](https://img.shields.io/badge/Version-0.1.13-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.2.0](https://img.shields.io/badge/AppVersion-1.2.0-informational?style=flat-square)

A Helm chart for gathering, scraping, and forwarding Kubernetes infrastructure metrics and logs to a Grafana Stack.

## Usage

### Setup Grafana chart repository

```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Install chart

To install the chart with the release name my-release:

```bash
cat >> values.yaml << EOF
cluster:
  name: my-cluster

externalServices:
  prometheus:
    host: https://prometheus.example.com
    username: "12345"
    password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    username: "67890"
    password: "It's a secret to everyone"
EOF
helm install my-release grafana/k8s-monitoring --values values.yaml
```

This chart simplifies the deployment of a Kubernetes monitoring infrastructure, including the following:

* [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics), which gathers metrics about Kubernetes objects
* [Node exporter](https://github.com/prometheus/node_exporter), which gathers metrics about Kubernetes nodes
* [OpenCost](https://www.opencost.io/), which interprets the above to create cost metrics for the cluster, and
* [Grafana Agent](https://grafana.com/docs/agent/latest/), which scrapes the above services to forward metrics to [Prometheus](https://prometheus.io/) and logs to [Loki](https://grafana.com/oss/loki/)

The Prometheus and Loki services may be hosted on the same cluster, or remotely (e.g. on Grafana Cloud).

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
| skl | <stephen.lang@grafana.com> |  |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://grafana.github.io/helm-charts | grafana-agent | 0.19.0 |
| https://grafana.github.io/helm-charts | grafana-agent-logs(grafana-agent) | 0.19.0 |
| https://opencost.github.io/opencost-helm-chart | opencost | 1.18.1 |
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 5.10.1 |
| https://prometheus-community.github.io/helm-charts | prometheus-node-exporter | 4.21.0 |
| https://prometheus-community.github.io/helm-charts | prometheus-operator-crds | 5.0.0 |
| https://prometheus-community.github.io/helm-charts | prometheus-windows-exporter | 0.1.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cluster.kubernetesAPIService | string | `"kubernetes.default.svc.cluster.local:443"` | The Kubernetes service. Change this if your cluster DNS is configured differently than the default. |
| cluster.name | string | `""` | (required) The name of this cluster, which will be set in all labels |
| externalServices.loki.basicAuth.password | string | `""` | Loki basic auth password |
| externalServices.loki.basicAuth.username | string | `""` | Loki basic auth username |
| externalServices.loki.externalLabels | object | `{}` | Custom labels to be added to all logs and events |
| externalServices.loki.host | string | `""` | (required) Loki host where logs and events will be sent |
| externalServices.loki.proxyURL | string | `""` | HTTP proxy to proxy requests to Loki through. |
| externalServices.loki.tenantId | string | `""` | (optional) Loki tenant ID |
| externalServices.loki.writeEndpoint | string | `"/loki/api/v1/push"` | Loki logs write endpoint |
| externalServices.prometheus.basicAuth.password | string | `""` | Prometheus basic auth password |
| externalServices.prometheus.basicAuth.username | string | `""` | Prometheus basic auth username |
| externalServices.prometheus.externalLabels | object | `{}` | Custom labels to be added to all time series |
| externalServices.prometheus.host | string | `""` | (required) Prometheus host where metrics will be sent |
| externalServices.prometheus.proxyURL | string | `""` | HTTP proxy to proxy requests to Prometheus through. |
| externalServices.prometheus.tenantId | string | `""` | (optional) Sets the X-Scope-OrgID header when sending metrics |
| externalServices.prometheus.writeEndpoint | string | `"/api/prom/push"` | Prometheus metrics write endpoint |
| extraConfig | string | `nil` | Extra configuration that will be added to the Grafana Agent configuration file. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example. |
| kube-state-metrics.enabled | bool | `true` | Should this helm chart deploy Kube State Metrics to the cluster. Set this to false if your cluster already has Kube State Metrics, or if you do not want to scrape metrics from Kube State Metrics. |
| logs.cluster_events.enabled | bool | `true` | Scrape Kubernetes cluster events |
| logs.enabled | bool | `true` | Capture and forward logs |
| logs.extraConfig | string | `nil` | Extra configuration that will be added to Grafana Agent Logs. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example.   |
| logs.pod_logs.enabled | bool | `true` | Capture and forward logs from Kubernetes pods |
| logs.pod_logs.extraRelabelingRules | string | `nil` | Rule blocks to be added to the discovery.relabel component for pod logs. See https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block |
| logs.pod_logs.extraStageBlocks | string | `nil` | Stage blocks to be added to the prometheus.relabel component for pod logs. See https://grafana.com/docs/agent/latest/flow/reference/components/loki.process/#blocks |
| logs.pod_logs.loggingFormat | string | `"docker"` | The log parsing format. Must be one of null, 'cri', or 'docker' See documentation: https://grafana.com/docs/agent/latest/flow/reference/components/loki.process/#stagecri-block |
| metrics.cadvisor.allowList | list | See [Allow List for cAdvisor](#allow-list-for-cadvisor) | The list of cAdvisor metrics that will be scraped by the Agent |
| metrics.cadvisor.enabled | bool | `true` | Scrape container metrics from cAdvisor |
| metrics.cadvisor.extraMetricRelabelingRules | string | `nil` | Rule blocks to be added to the prometheus.relabel component for cAdvisor. See https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block |
| metrics.cadvisor.extraRelabelingRules | string | `nil` | Rule blocks to be added to the discovery.relabel component for cAdvisor. See https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block |
| metrics.cost.allowList | list | See [Allow List for OpenCost](#allow-list-for-opencost) | The list of OpenCost metrics that will be scraped by the Agent |
| metrics.cost.enabled | bool | `true` | Scrape cost metrics from OpenCost |
| metrics.cost.extraMetricRelabelingRules | string | `nil` | Rule blocks to be added to the prometheus.relabel component for OpenCost. See https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block |
| metrics.cost.extraRelabelingRules | string | `nil` | Rule blocks to be added to the discovery.relabel component for OpenCost. See https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block |
| metrics.cost.labelMatchers | object | `{"app.kubernetes.io/name":"opencost"}` | Label matchers used by the Grafana Agent to select the OpenCost service |
| metrics.enabled | bool | `true` | Capture and forward metrics |
| metrics.extraMetricRelabelingRules | string | `nil` | Rule blocks to be added to the prometheus.relabel component for all metric sources. See https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block |
| metrics.extraRelabelingRules | string | `nil` | Rule blocks to be added to the discovery.relabel component for all metric sources. See https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block |
| metrics.kube-state-metrics.allowList | list | See [Allow List for Kube State Metrics](#allow-list-for-kube-state-metrics) | The list of Kube State Metrics metrics that will be scraped by the Agent |
| metrics.kube-state-metrics.enabled | bool | `true` | Scrape cluster object metrics from Kube State Metrics |
| metrics.kube-state-metrics.extraMetricRelabelingRules | string | `nil` | Rule blocks to be added to the prometheus.relabel component for Kube State Metrics. See https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block |
| metrics.kube-state-metrics.extraRelabelingRules | string | `nil` | Rule blocks to be added to the discovery.relabel component for Kube State Metrics. See https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block |
| metrics.kube-state-metrics.labelMatchers | object | `{"app.kubernetes.io/name":"kube-state-metrics"}` | Label matchers used by the Grafana Agent to select the Kube State Metrics service |
| metrics.kube-state-metrics.service.isTLS | bool | `false` | Does this port use TLS? |
| metrics.kube-state-metrics.service.port | string | `"http"` | Name of the metrics port |
| metrics.kubelet.allowList | list | See [Allow List for Kubelet](#allow-list-for-kubelet) | The list of Kubelet metrics that will be scraped by the Agent |
| metrics.kubelet.enabled | bool | `true` | Scrape cluster metrics from the Kubelet |
| metrics.kubelet.extraMetricRelabelingRules | string | `nil` | Rule blocks to be added to the prometheus.relabel component for Kubelet. See https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block |
| metrics.kubelet.extraRelabelingRules | string | `nil` | Rule blocks to be added to the discovery.relabel component for Kubelet. See https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block |
| metrics.node-exporter.allowList | list | See [Allow List for Node Exporter](#allow-list-for-node-exporter) | The list of Node Exporter metrics that will be scraped by the Agent |
| metrics.node-exporter.enabled | bool | `true` | Scrape node metrics |
| metrics.node-exporter.extraMetricRelabelingRules | string | `nil` | Rule blocks to be added to the prometheus.relabel component for Node Exporter. See https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block |
| metrics.node-exporter.extraRelabelingRules | string | `nil` | Rule blocks to be added to the discovery.relabel component for Node Exporter. See https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block |
| metrics.node-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"prometheus-node-exporter.*"}` | Label matchers used by the Grafana Agent to select the Node exporter pods |
| metrics.node-exporter.service.isTLS | bool | `false` | Does this port use TLS? |
| metrics.podMonitors.enabled | bool | `true` | Include service discovery for PodMonitor objects |
| metrics.serviceMonitors.enabled | bool | `true` | Include service discovery for ServiceMonitor objects |
| metrics.windows-exporter.allowList | list | See [Allow List for Windows Exporter](#allow-list-for-windows-exporter) | The list of Windows Exporter metrics that will be scraped by the Agent |
| metrics.windows-exporter.enabled | bool | `false` | Scrape node metrics |
| metrics.windows-exporter.extraMetricRelabelingRules | string | `nil` | Rule blocks to be added to the prometheus.relabel component for Windows Exporter. See https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block |
| metrics.windows-exporter.extraRelabelingRules | string | `nil` | Rule blocks to be added to the discovery.relabel component for Windows Exporter. See https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block |
| metrics.windows-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"prometheus-windows-exporter.*"}` | Label matchers used by the Grafana Agent to select the Windows Exporter pods |
| opencost.enabled | bool | `true` | Should this Helm chart deploy OpenCost to the cluster. Set this to false if your cluster already has OpenCost, or if you do not want to scrape metrics from OpenCost. |
| opencost.opencost.prometheus.external.url | string | `"https://prom.example.com/api/prom"` | The URL for Prometheus queries. It should match externalService.prometheus.host + "/api/prom" |
| prometheus-node-exporter.enabled | bool | `true` | Should this helm chart deploy Node Exporter to the cluster. Set this to false if your cluster already has Node Exporter, or if you do not want to scrape metrics from Node Exporter. |
| prometheus-operator-crds.enabled | bool | `true` | Should this helm chart deploy the Prometheus Operator CRDs to the cluster. Set this to false if your cluster already has the CRDs, or if you do not to have the Grafana Agent scrape metrics from PodMonitors or ServiceMonitors. |
| prometheus-windows-exporter.config | string | `"collectors:\n  enabled: cpu,cs,container,logical_disk,memory,net,os\ncollector:\n  service:\n    services-where: \"Name='containerd' or Name='kubelet'\""` |  |
| prometheus-windows-exporter.enabled | bool | `false` | Should this helm chart deploy Windows Exporter to the cluster. Set this to false if your cluster already has Windows Exporter, or if you do not want to scrape metrics from Windows Exporter. |

## Customizing the configuration

There are several options for customizing the configuration generated by this chart. This can be used to add extra
scrape targets, for example, to [scrape metrics from an application](./docs/ScrapeApplicationMetrics.md) deployed on the
same Kubernetes cluster.

### Adding custom Flow configuration

Any value supplied to the `.extraConfig` or `.logs.extraConfig` values will be appended to the generated config file.
This can be used to add Grafana Agent Flow components to provide extra functionality to the agent.

Extra flow components can re-use any of the existing components in the generated configuration, which includes several
useful ones like these:

* `discovery.kubernetes.nodes` - Discovers all nodes in the cluster
* `discovery.kubernetes.pods` - Discovers all pods in the cluster
* `discovery.kubernetes.services` - Discovers all services in the cluster
* `prometheus.remote_write.grafana_cloud_prometheus` - Sends metrics to Prometheus defined by `.externalService.prometheus`
* `loki.write.grafana_cloud_loki` - Sends logs to Loki defined by `.externalService.loki`

Example:

In this example, the Agent will find a service named `my-webapp-metrics` with the label
`app.kubernetes.io/name=my-webapp`, scrape them for Prometheus metrics, and send those metrics to Grafana Cloud.

```yaml
extraConfig: |-
  discovery.relabel "my_webapp" {
    targets = discovery.kubernetes.services.targets
    rule {
      source_labels = ["__meta_kubernetes_service_name"]
      regex = "my-webapp-metrics"
      action = "keep"
    }
    rule {
      source_labels = ["__meta_kubernetes_service_label_app_kubernetes_io_name"]
      regex = "my-webapp"
      action = "keep"
    }
  }

  prometheus.scrape "my_webapp" {
    job_name   = "my_webapp"
    targets    = discovery.relabel.my_webapp.output
    forward_to = [prometheus.remote_write.grafana_cloud_prometheus.receiver]
  }
```

For an example values file and generated output, see [this example](../../examples/custom-config).

### Using Prometheus Operator CRDs

The default config can deploy the CRDs for Prometheus Operator, and will add support for `PodMonitor` and
`ServiceMonitor` objects.

Simply deploy a PodMonitor or a ServiceMonitor in the same namespace as the Grafana Agent and it will discover it and
take the appropriate action.

## Platform-specific instructions

### OpenShift

If your cluster is on OpenShift, this Helm chart can be configured to scrape metrics from the existing Kube State Metrics and Node exporter that are deployed by [OpenShift Container Platform monitoring](https://docs.openshift.com/container-platform/latest/monitoring/monitoring-overview.html).
Use the following values file as a starting point for your own cluster:

```yaml
cluster:
  name: my-openshift-cluster

externalServices:
  prometheus:
    host: https://prometheus.example.com
    username: "12345"
    password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    username: "67890"
    password: "It's a secret to everyone"

metrics:
  kube-state-metrics:
    service:
      port: https-main
      isTLS: true

  node-exporter:
    labelMatchers:
      app.kubernetes.io/name: node-exporter
    service:
      isTLS: true

kube-state-metrics: # This disables the deployment of Kube State Metrics
  enabled: false

prometheus-node-exporter: # This disables the deployment of Node exporter
  enabled: false

grafana-agent:
  agent:
    listenPort: 8080
```

For an example values file and generated output, see [this example](../../examples/openshift-compatible).

## Allow List

Each metric source has an allow list, which is a list of metric names that will
be forwarded by the Grafana Agent to Prometheus. Any metric not on that list
will be ignored. Defaults have been supplied for the specific services and are
shown in the following sections.

If you want to allow all metrics, set this in the values file:

```yaml
allowList: null
```

For more examples of custom allow lists, see [this example](../../examples/custom-allow-lists).

### Allow List for Kube State Metrics

Visit the Kube State Metrics [documentation](https://github.com/kubernetes/kube-state-metrics/tree/main/docs#exposed-metrics) for the full list of metrics

* kube_daemonset.*
* kube_deployment_metadata_generation
* kube_deployment_spec_replicas
* kube_deployment_status_observed_generation
* kube_deployment_status_replicas_available
* kube_deployment_status_replicas_updated
* kube_horizontalpodautoscaler_spec_max_replicas
* kube_horizontalpodautoscaler_spec_min_replicas
* kube_horizontalpodautoscaler_status_current_replicas
* kube_horizontalpodautoscaler_status_desired_replicas
* kube_job.*
* kube_namespace_status_phase
* kube_namespace_status_phase
* kube_node.*
* kube_persistentvolumeclaim_resource_requests_storage_bytes
* kube_pod_container_info
* kube_pod_container_resource_limits
* kube_pod_container_resource_requests
* kube_pod_container_status_restarts_total
* kube_pod_container_status_waiting_reason
* kube_pod_container_status_waiting_reason
* kube_pod_info
* kube_pod_owner
* kube_pod_start_time
* kube_pod_status_phase
* kube_pod_status_phase
* kube_pod_status_reason
* kube_replicaset.*
* kube_resourcequota
* kube_statefulset.*

### Allow List for Node Exporter

* node_cpu.*
* node_exporter_build_info
* node_filesystem.*
* node_memory.*
* process_cpu_seconds_total
* process_resident_memory_bytes

### Allow List for Windows Exporter

* windows_.*
* node_cpu_seconds_total
* node_filesystem_size_bytes
* node_filesystem_avail_bytes
* container_cpu_usage_seconds_total

### Allow List for Kubelet

Visit the Kubelet [documentation](https://github.com/kubernetes/kubernetes/blob/master/test/instrumentation/documentation/documentation.md) for the full list of metrics

* container_cpu_usage_seconds_total
* kubelet_certificate_manager_client_expiration_renew_errors
* kubelet_certificate_manager_client_ttl_seconds
* kubelet_certificate_manager_server_ttl_seconds
* kubelet_cgroup_manager_duration_seconds_bucket
* kubelet_cgroup_manager_duration_seconds_count
* kubelet_node_config_error
* kubelet_node_name
* kubelet_pleg_relist_duration_seconds_bucket
* kubelet_pleg_relist_duration_seconds_count
* kubelet_pleg_relist_interval_seconds_bucket
* kubelet_pod_start_duration_seconds_bucket
* kubelet_pod_start_duration_seconds_count
* kubelet_pod_worker_duration_seconds_bucket
* kubelet_pod_worker_duration_seconds_count
* kubelet_running_container_count
* kubelet_running_containers
* kubelet_running_pod_count
* kubelet_running_pods
* kubelet_runtime_operations_errors_total
* kubelet_runtime_operations_total
* kubelet_server_expiration_renew_errors
* kubelet_volume_stats_available_bytes
* kubelet_volume_stats_capacity_bytes
* kubelet_volume_stats_inodes
* kubelet_volume_stats_inodes_used
* kubernetes_build_info
* namespace_workload_pod
* rest_client_requests_total
* storage_operation_duration_seconds_count
* storage_operation_errors_total
* volume_manager_total_volumes

### Allow List for cAdvisor

Visit the cAdvisor [documentation](https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md)

* container_cpu_cfs_periods_total
* container_cpu_cfs_throttled_periods_total
* container_cpu_usage_seconds_total
* container_fs_reads_bytes_total
* container_fs_reads_total
* container_fs_writes_bytes_total
* container_fs_writes_total
* container_memory_cache
* container_memory_rss
* container_memory_swap
* container_memory_working_set_bytes
* container_network_receive_bytes_total
* container_network_receive_packets_dropped_total
* container_network_receive_packets_total
* container_network_transmit_bytes_total
* container_network_transmit_packets_dropped_total
* container_network_transmit_packets_total
* machine_memory_bytes

### Allow List for OpenCost

Visit the OpenCost [documentation](https://www.opencost.io/docs/prometheus#available-metrics) for the full list of metrics

* container_cpu_allocation
* container_gpu_allocation
* container_memory_allocation_bytes
* deployment_match_labels
* kubecost_cluster_info
* kubecost_cluster_management_cost
* kubecost_cluster_memory_working_set_bytes
* kubecost_http_requests_total
* kubecost_http_response_size_bytes
* kubecost_http_response_time_seconds
* kubecost_load_balancer_cost
* kubecost_network_internet_egress_cost
* kubecost_network_region_egress_cost
* kubecost_network_zone_egress_cost
* kubecost_node_is_spot
* node_cpu_hourly_cost
* node_gpu_count
* node_gpu_hourly_cost
* node_ram_hourly_cost
* node_total_hourly_cost
* opencost_build_info
* pod_pvc_allocation
* pv_hourly_cost
* service_selector_labels
* statefulSet_match_labels
