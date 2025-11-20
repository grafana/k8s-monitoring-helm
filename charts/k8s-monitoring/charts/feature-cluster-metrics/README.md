<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Cluster Metrics

This chart deploys the Cluster Metrics feature of the Kubernetes Observability Helm chart, which uses allow
lists to limit the metrics needed. An allow list is a set of metric names that will be kept, while any metrics
not on the list will be dropped. With [metrics tuning](#metrics-tuning--allow-lists), you can further customize which metrics are collected.

## Usage

```yaml
clusterMetrics:
  enabled: true
```

## How it works

This chart includes the ability to collect metrics from the following:

*   The Kubernetes cluster itself
*   Sources like the Kubelet and cAdvisor
*   Common supporting services like [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) and
    [Node Exporter](https://github.com/prometheus/node_exporter)
*   Systems to capture additional data like Kepler

### Metrics sources

The Cluster Metrics feature of the Kubernetes Observability Helm chart includes the following metric systems and
their default allow lists:

| Metric source                                                                | Gathers information about                                                                    | Allow list                                                                                                                                                                                     |
|------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| API Server                                                                   | Kubernetes API Server                                                                        | NA                                                                                                                                                                                             |
| [cAdvisor](https://github.com/google/cadvisor)                               | Containers on each node                                                                      | [default-allow-lists/cadvisor.yaml](./default-allow-lists/cadvisor.yaml)                                                                                                                       |
| [Kepler](https://sustainable-computing.io/)                                  | Kubernetes cluster                                                                           | [default-allow-lists/kepler.yaml](./default-allow-lists/kepler.yaml)                                                                                                                           |
| Kube Controller Manager                                                      | Kubernetes Controller Manager                                                                | NA                                                                                                                                                                                             |
| Kube Proxy                                                                   | Kube Proxy                                                                                   | NA                                                                                                                                                                                             |
| Kube Scheduler                                                               | Kube Scheduler                                                                               | NA                                                                                                                                                                                             |
| Kubelet                                                                      | Kubernetes information on each node                                                          | [default-allow-lists/kubelet.yaml](./default-allow-lists/kubelet.yaml)                                                                                                                         |
| [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)       | Kubernetes                                                                                   |                                                                                                                                                                                                |
| resources inside the cluster                                                 | [default-allow-lists/kube-state-metrics.yaml](./default-allow-lists/kube-state-metrics.yaml) |                                                                                                                                                                                                |
| [Node Exporter](https://github.com/prometheus/node_exporter)                 | Linux Kubernetes nodes                                                                       | [default-allow-lists/node-exporter.yaml](./default-allow-lists/node-exporter.yaml), [default-allow-lists/node-exporter-integration.yaml](./default-allow-lists/node-exporter-integration.yaml) |
| [Windows Exporter](https://github.com/prometheus-community/windows_exporter) | Windows Kubernetes nodes                                                                     | [default-allow-lists/windows-exporter.yaml](./default-allow-lists/windows-exporter.yaml)                                                                                                       |

## Metrics tuning and allow lists

For any metric source, you can adjust the amount of metrics being scraped and their labels to limit the number of metrics delivered to your destinations. Many of the metric sources have a default allow list. The allow list for a metric source is designed to return a useful, but minimal set of metrics for typical use cases. Some metrics sources have an integration allow list, which contains even more metrics for diving into the details of the source itself.

To control metrics with allow lists or label filters, use the `metricsTuning` section in the values file.

```yaml
<metric source>:
  metricsTuning:
    useDefaultAllowList: <boolean>      # Use the allow list for this metric source
    useIntegrationAllowList: <boolean>  # Use the integration allow list for this metric source
    includeMetrics: [<string>]          # Metrics to be kept
    excludeMetrics: [<string>]          # Metrics to be dropped
```

The behavior of the combination of these settings is shown in this table:

| Allow list | includeMetrics   | excludeMetrics           | Result                                                                                                                                  |
|------------|------------------|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| true       | `[]`             | `[]`                     | Use the allow list metric list                                                                                                          |
| false      | `[]`             | `[]`                     | No filter, keep all metrics                                                                                                             |
| true       | `[my_metric]`    | `[]`                     | Use the allow list metric list with an additional metric                                                                                |
| false      | `[my_metric_.*]` | `[]`                     | *Only* keep metrics that start with `my_metric_`                                                                                        |
| true       | `[]`             | `[my_metric_.*]`         | Use the allow list metric filter, but exclude anything that starts with `my_metric_`                                                    |
| false      | `[]`             | `[my_metric_.*]`         | Keep all metrics except anything that starts with `my_metric_`                                                                          |
| true       | `[my_metric_.*]` | `[other_metric_.*]`      | Use the allow list metric filter, and keep anything that starts with `my_metric_`, but remove anything that starts with `other_metric_` |
| false      | `[my_metric_.*]` | `[my_metric_not_needed]` | *Only* keep metrics that start with `my_metric_`, but remove any that are named `my_metric_not_needed`                                  |

## Relabeling rules

You can also use relabeling rules to take any action on the metrics allow list, such as to filter based on a label.
To do so, use `extraMetricProcessingRules` section in the values file to add arbitrary relabeling rules.

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `deployAsConfigMap` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

<!-- textlint-disable terminology -->
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- textlint-enable terminology -->

<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cluster-metrics>
<!-- markdownlint-enable list-marker-space -->

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://opencost.github.io/opencost-helm-chart | opencost | 2.3.2 |
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 6.4.1 |
| https://prometheus-community.github.io/helm-charts | node-exporter(prometheus-node-exporter) | 4.49.1 |
| https://prometheus-community.github.io/helm-charts | windows-exporter(prometheus-windows-exporter) | 0.12.2 |
| https://sustainable-computing-io.github.io/kepler-helm-chart | kepler | 0.6.1 |
<!-- markdownlint-enable no-bare-urls -->

<!-- markdownlint-disable no-space-in-emphasis -->
## Values

### API Server

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| apiServer.enabled | bool | `false` | Scrape metrics from the API Server. |
| apiServer.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the API Server. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| apiServer.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the API Server. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| apiServer.jobLabel | string | `"integrations/kubernetes/kube-apiserver"` | The value for the job label. |
| apiServer.maxCacheSize | string | `nil` | Sets the max_cache_size for the API Server prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| apiServer.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| apiServer.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| apiServer.scrapeInterval | string | 60s | How frequently to scrape metrics from the API Server Overrides metrics.scrapeInterval |
| apiServer.scrapeTimeout | string | `10s` | The timeout for scraping API Server metrics. |

### cAdvisor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cadvisor.enabled | bool | `true` | Scrape metrics from cAdvisor. |
| cadvisor.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for cAdvisor. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| cadvisor.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for cAdvisor metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| cadvisor.jobLabel | string | `"integrations/kubernetes/cadvisor"` | The value for the job label. |
| cadvisor.maxCacheSize | string | `100000` | Sets the max_cache_size for the cAdvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| cadvisor.metricsTuning.dropEmptyContainerLabels | bool | `true` | Drop metrics that have an empty container label |
| cadvisor.metricsTuning.dropEmptyImageLabels | bool | `true` | Drop metrics that have an empty image label |
| cadvisor.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| cadvisor.metricsTuning.excludeNamespaces | list | `[]` | For metrics with a `namespace` label, drop those that are in this list. |
| cadvisor.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| cadvisor.metricsTuning.includeNamespaces | list | `[]` | For metrics with a `namespace` label, only keep those that are in this list. |
| cadvisor.metricsTuning.keepPhysicalFilesystemDevices | list | `["mmcblk.p.+","nvme.+","rbd.+","sd.+","vd.+","xvd.+","dasd.+"]` | Only keep filesystem metrics that use the following physical devices |
| cadvisor.metricsTuning.keepPhysicalNetworkDevices | list | `["en[ospx][0-9].*","wlan[0-9].*","eth[0-9].*"]` | Only keep network metrics that use the following physical devices |
| cadvisor.metricsTuning.normalizeUnnecessaryLabels | list | `[{"labels":["boot_id","system_uuid"],"metric":"machine_memory_bytes"}]` | Normalize labels to the same value for the given metric and label pairs |
| cadvisor.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from cAdvisor to the minimal set required for Kubernetes Monitoring. |
| cadvisor.nodeAddressFormat | string | `"direct"` | How to access cAdvisor to get metrics, either "direct" (use node IP) or "proxy" (uses API Server) |
| cadvisor.scrapeTimeout | string | `10s` | The timeout for scraping cAdvisor metrics. |

### cadvisor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cadvisor.scrapeInterval | string | `60s` | How frequently to scrape cAdvisor metrics. |

### Control Plane

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controlPlane.enabled | bool | `false` | enable all Kubernetes Control Plane metrics sources. This includes api-server, kube-scheduler, kube-controller-manager, and KubeDNS. |

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

### Kepler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kepler.enabled | bool | `false` | Deploy and scrape Kepler metrics. |
| kepler.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kepler. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kepler.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kepler. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no __meta* labels are present. |
| kepler.jobLabel | string | `"integrations/kepler"` | The value for the job label. |
| kepler.labelMatchers | object | `{"app.kubernetes.io/name":"kepler"}` | Label matchers used to select the Kepler pods |
| kepler.maxCacheSize | string | `100000` | Sets the max_cache_size for the prometheus.relabel component for Kepler. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| kepler.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kepler.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| kepler.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kepler to the minimal set required for Kubernetes Monitoring. |
| kepler.scrapeInterval | string | `60s` | How frequently to scrape metrics from Kepler. Overrides global.scrapeInterval. |
| kepler.scrapeTimeout | string | `10s` | The timeout for scraping Kepler metrics. |

### kube-state-metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-state-metrics.bearerTokenFile | string | `""` | The bearer token file to use when scraping metrics from kube-state-metrics. |
| kube-state-metrics.deploy | bool | `true` | Deploy kube-state-metrics. Set to false if your cluster already has kube-state-metrics deployed. |
| kube-state-metrics.discoveryType | string | `"endpoints"` | How to discover the kube-state-metrics service. Either `endpoints`, `pod`, or `service`. Use `service` if you know there is a single kube-state-metrics replica, or are using HA. Use `endpoints` or `pod` if you have multiple replicas with auto-sharding. |
| kube-state-metrics.enabled | bool | `true` | Scrape metrics from kube-state-metrics. |
| kube-state-metrics.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for kube-state-metrics. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kube-state-metrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for kube-state-metrics metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kube-state-metrics.jobLabel | string | `"integrations/kubernetes/kube-state-metrics"` | The value for the job label. |
| kube-state-metrics.labelMatchers | object | `{"app.kubernetes.io/name":"kube-state-metrics"}` | Labels used to select the kube-state-metrics service. |
| kube-state-metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for the kube-state-metrics prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| kube-state-metrics.metricLabelsAllowlist | list | `["nodes=[agentpool,alpha.eksctl.io/cluster-name,alpha.eksctl.io/nodegroup-name,beta.kubernetes.io/instance-type,cloud.google.com/gke-nodepool,cluster-name,ec2.amazonaws.com/Name,ec2.amazonaws.com/aws-autoscaling-groupName,ec2.amazonaws.com/aws-autoscaling-group-name,ec2.amazonaws.com/name,eks.amazonaws.com/nodegroup,k8s.io/cloud-provider-aws,karpenter.sh/nodepool,kubernetes.azure.com/cluster,kubernetes.io/arch,kubernetes.io/hostname,kubernetes.io/os,node.kubernetes.io/instance-type,topology.kubernetes.io/region,topology.kubernetes.io/zone]"]` | `kube_<resource>_labels` metrics to generate. The default is to include a useful set for Node labels. |
| kube-state-metrics.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kube-state-metrics.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| kube-state-metrics.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kube State Metrics to a useful, minimal set. |
| kube-state-metrics.namespace | string | `""` | Namespace to locate kube-state-metrics pods. If `deploy` is set to `true`, this will automatically be set to the namespace where this Helm chart is deployed. |
| kube-state-metrics.namespaces | list | `[]` | List (or comma-separated string) of namespaces to be enabled for collecting resources. By default, all namespaces are collected. Requires kube-state-metrics to be deployed by this chart. |
| kube-state-metrics.namespacesDenylist | list | `[]` | List (or comma-separated string) of namespaces to be excluded from collecting resources. If namespaces and namespaces denylist are both set, only namespaces that are excluded in namespaces denylist will be used. Requires kube-state-metrics to be deployed by this chart. |
| kube-state-metrics.scrapeInterval | string | `60s` | How frequently to scrape kube-state-metrics metrics. |
| kube-state-metrics.scrapeTimeout | string | `10s` | The timeout for scraping kube-state-metrics metrics. |
| kube-state-metrics.service.portName | string | `"http"` | The port name used by kube-state-metrics. |
| kube-state-metrics.service.scheme | string | `"http"` | The scrape scheme used by kube-state-metrics. |

### Kube Controller Manager

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeControllerManager.enabled | bool | `false` | Scrape metrics from the Kube Controller Manager |
| kubeControllerManager.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Controller Manager. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeControllerManager.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Controller Manager. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeControllerManager.jobLabel | string | `"kube-controller-manager"` | The value for the job label. |
| kubeControllerManager.maxCacheSize | string | `nil` | Sets the max_cache_size for the Kube Controller Manager prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| kubeControllerManager.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeControllerManager.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| kubeControllerManager.port | int | `10257` | Port number used by the Kube Controller Manager, set by `--secure-port.` |
| kubeControllerManager.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Controller Manager Overrides metrics.scrapeInterval |
| kubeControllerManager.selectorLabel | string | `"component=kube-controller-manager"` | Selector label. |

### KubeDNS

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeDNS.enabled | bool | `false` | Scrape metrics from KubeDNS |
| kubeDNS.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for KubeDNS. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeDNS.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for KubeDNS. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeDNS.jobLabel | string | `"integrations/kubernetes/kube-dns"` | The value for the job label. |
| kubeDNS.maxCacheSize | string | `nil` | Sets the max_cache_size for the KubeDNS prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| kubeDNS.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeDNS.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| kubeDNS.scrapeInterval | string | 60s | How frequently to scrape metrics from KubeDNS Overrides metrics.scrapeInterval |
| kubeDNS.scrapeTimeout | string | `10s` | The timeout for scraping KubeDNS metrics. |

### Kube Proxy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeProxy.enabled | bool | `false` | Scrape metrics from the Kube Proxy |
| kubeProxy.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Proxy. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeProxy.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Proxy. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeProxy.jobLabel | string | `"integrations/kubernetes/kube-proxy"` | The value for the job label. |
| kubeProxy.maxCacheSize | string | `nil` | Sets the max_cache_size for the Kube Proxy prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| kubeProxy.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeProxy.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| kubeProxy.port | int | `10249` | Port number used by the Kube Proxy, set in `--metrics-bind-address`. |
| kubeProxy.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Proxy Overrides metrics.scrapeInterval |
| kubeProxy.scrapeTimeout | string | `10s` | The timeout for scraping Kube Proxy metrics. |
| kubeProxy.selectorLabel | string | `"k8s-app=kube-proxy"` | Selector label. |

### Kube Scheduler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeScheduler.enabled | bool | `false` | Scrape metrics from the Kube Scheduler |
| kubeScheduler.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Scheduler. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeScheduler.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Scheduler. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeScheduler.jobLabel | string | `"kube-scheduler"` | The value for the job label. |
| kubeScheduler.maxCacheSize | string | `nil` | Sets the max_cache_size for the Kube Scheduler prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| kubeScheduler.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeScheduler.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| kubeScheduler.port | int | `10259` | Port number used by the Kube Scheduler, set by `--secure-port`. |
| kubeScheduler.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Scheduler Overrides metrics.scrapeInterval |
| kubeScheduler.scrapeTimeout | string | `10s` | The timeout for scraping Kube Scheduler metrics. |
| kubeScheduler.selectorLabel | string | `"component=kube-scheduler"` | Selector label. |

### Kubelet

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubelet.enabled | bool | `true` | Scrape metrics from kubelet. |
| kubelet.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kubelet. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubelet.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kubelet metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubelet.jobLabel | string | `"integrations/kubernetes/kubelet"` | The value for the job label. |
| kubelet.maxCacheSize | string | `100000` | Sets the max_cache_size for the Kubelet prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| kubelet.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubelet.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| kubelet.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from the Kubelet to the minimal set required for Kubernetes Monitoring. |
| kubelet.nodeAddressFormat | string | `"direct"` | How to access the Kubelet to get metrics, either "direct" (use node IP) or "proxy" (uses API Server) |
| kubelet.scrapeInterval | string | `60s` | How frequently to scrape Kubelet metrics. |
| kubelet.scrapeTimeout | string | `10s` | The timeout for scraping Kubelet metrics. |

### Kubelet Probes

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeletProbes.enabled | bool | `false` | Scrape probe metrics from the Kubelet. |
| kubeletProbes.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kubelet probes. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeletProbes.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kubelet probe metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeletProbes.jobLabel | string | `"integrations/kubernetes/probes"` | The value for the job label. |
| kubeletProbes.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel components. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| kubeletProbes.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeletProbes.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| kubeletProbes.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of probe metrics from the Kubelet to the minimal set required for Kubernetes Monitoring. |
| kubeletProbes.nodeAddressFormat | string | `"direct"` | How to access the Kubelet to get probe metrics, either "direct" (use node IP) or "proxy" (uses API Server) |
| kubeletProbes.scrapeInterval | string | `60s` | How frequently to scrape Kubelet probe metrics. |
| kubeletProbes.scrapeTimeout | string | `10s` | The timeout for scraping Kubelet probe metrics. |

### Kubelet Resources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeletResource.enabled | bool | `true` | Scrape resource metrics from the Kubelet. |
| kubeletResource.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kubelet resources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeletResource.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kubelet resource metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeletResource.jobLabel | string | `"integrations/kubernetes/resources"` | The value for the job label. |
| kubeletResource.maxCacheSize | string | `100000` | Sets the max_cache_size for prometheus.relabel components. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| kubeletResource.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeletResource.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| kubeletResource.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of resource metrics from the Kubelet to the minimal set required for Kubernetes Monitoring. |
| kubeletResource.nodeAddressFormat | string | `"direct"` | How to access the Kubelet to get resource metrics, either "direct" (use node IP) or "proxy" (uses API Server) |
| kubeletResource.scrapeInterval | string | `60s` | How frequently to scrape Kubelet resource metrics. |
| kubeletResource.scrapeTimeout | string | `10s` | The timeout for scraping Kubelet resource metrics. |

### Node Exporter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| node-exporter.bearerTokenFile | string | `""` | The bearer token file to use when scraping metrics from Node Exporter. |
| node-exporter.deploy | bool | `true` | Deploy Node Exporter. Set to false if your cluster already has Node Exporter deployed. |
| node-exporter.enabled | bool | `true` | Scrape metrics from Node Exporter. |
| node-exporter.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Node Exporter. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| node-exporter.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Node Exporter metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| node-exporter.jobLabel | string | `"integrations/node_exporter"` | The value for the job label. |
| node-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"node-exporter"}` | Labels used to select the Node Exporter pods. |
| node-exporter.maxCacheSize | string | `100000` | Sets the max_cache_size for the Node Exporter prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| node-exporter.metricsTuning.dropMetricsForFilesystem | list | `["ramfs","tmpfs"]` | Drop metrics for the given filesystem types |
| node-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| node-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| node-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring. |
| node-exporter.metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring as well as the Node Exporter integration. |
| node-exporter.namespace | string | `""` | Namespace to locate Node Exporter pods. If `deploy` is set to `true`, this will automatically be set to the namespace where this Helm chart is deployed. |
| node-exporter.scrapeInterval | string | `60s` | How frequently to scrape Node Exporter metrics. |
| node-exporter.scrapeTimeout | string | `10s` | The timeout for scraping Node Exporter metrics. |
| node-exporter.service.portName | string | `"metrics"` | The port name used by Node Exporter. |
| node-exporter.service.scheme | string | `"http"` | The scrape scheme used by Node Exporter. |

### Node Labels

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nodeLabels.availabilityZone | bool | `false` | Whether or not to add the availability\_zone label |
| nodeLabels.instanceType | bool | `false` | Whether or not to add the instance\_type label |
| nodeLabels.nodeArchitecture | bool | `false` | Whether or not to add the node architecture label |
| nodeLabels.nodeOS | bool | `false` | Whether or not to add the os label |
| nodeLabels.nodePool | bool | `false` | Whether or not to attach the nodepool label |
| nodeLabels.nodeRole | bool | `false` | Whether or not to add the node\_role label |
| nodeLabels.region | bool | `false` | Whether or not to add the region label |

### OpenCost

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| opencost.enabled | bool | `false` | Deploy and scrape OpenCost. |
| opencost.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for OpenCost. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| opencost.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for OpenCost. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no __meta* labels are present. |
| opencost.jobLabel | string | `"integrations/opencost"` | The value for the job label. |
| opencost.labelMatchers | object | `{"app.kubernetes.io/name":"opencost"}` | Label matchers used to select the OpenCost service |
| opencost.maxCacheSize | string | `100000` | Sets the max_cache_size for the prometheus.relabel component for OpenCost. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| opencost.metricsSource | string | `""` | The name of the metric destination where OpenCost will query for required metrics. Setting this will enable guided setup for required OpenCost parameters. To skip guided setup, set this to "custom". |
| opencost.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| opencost.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| opencost.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from OpenCost to the minimal set required for Kubernetes Monitoring. |
| opencost.opencost.prometheus.existingSecretName | string | `""` | The name of the secret containing the username and password for the metrics service. This must be in the same namespace as the OpenCost deployment. |
| opencost.opencost.prometheus.external.url | string | `""` | The URL for Prometheus queries. It should match externalServices.prometheus.host + "/api/prom" |
| opencost.opencost.prometheus.password_key | string | `"password"` | The key for the password property in the secret. |
| opencost.opencost.prometheus.username_key | string | `"username"` | The key for the username property in the secret. |
| opencost.scrapeInterval | string | `60s` | How frequently to scrape metrics from Kepler. Overrides global.scrapeInterval. |
| opencost.scrapeTimeout | string | `10s` | The timeout for scraping OpenCost metrics. |

### Windows Exporter - Deployment settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| windows-exporter.deploy | bool | `true` | Deploy Windows Exporter. Set to false if your cluster already has Windows Exporter deployed. |

### Windows Exporter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| windows-exporter.enabled | bool | `true` | Scrape node metrics |
| windows-exporter.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Windows Exporter. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| windows-exporter.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Windows Exporter metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| windows-exporter.jobLabel | string | `"integrations/windows-exporter"` | The value for the job label. |
| windows-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"windows-exporter"}` | Labels used to select the Windows Exporter pods. |
| windows-exporter.maxCacheSize | string | `100000` | Sets the max_cache_size for the Windows Exporter prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| windows-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| windows-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| windows-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Windows Exporter to the minimal set required for Kubernetes Monitoring. |
| windows-exporter.namespace | string | `""` | Namespace to locate Windows Exporter pods. If `deploy` is set to `true`, this will automatically be set to the namespace where this Helm chart is deployed. |
| windows-exporter.scrapeInterval | string | `60s` | How frequently to scrape metrics from Windows Exporter. |
| windows-exporter.scrapeTimeout | string | `10s` | The timeout for scraping Windows Exporter metrics. |
| windows-exporter.service.portName | string | `"metrics"` | The port name used by Windows Exporter. |
<!-- markdownlint-enable no-space-in-emphasis -->
