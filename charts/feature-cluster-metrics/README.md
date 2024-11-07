<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring-feature-cluster-metrics

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Gathers Kubernetes Cluster metrics

This chart deploys the Cluster Metrics feature of the Kubernetes Observability Helm chart. It includes the ability to
collect metrics from the Kubernetes Cluster itself, from sources like the Kubelet and cAdvisor, from common supporting
services like [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) and
[Node Exporter](https://github.com/prometheus/node_exporter), and from systems to capture additional data like Kepler.

## Metric systems

The Cluster Metrics feature of the Kubernetes Observability Helm chart includes the following metric systems:

*   Kubelet
*   cAdvisor
*   API Server
*   Kube Controller Manager
*   Kube Proxy
*   Kube Scheduler
*   kube-state-metrics
*   Node Exporter
*   Windows Exporter
*   Kepler

### Kubelet

Kubelet metrics gather information about Kubernetes information on each node.

The kubelet metric source uses an [allow list](#metrics-tuning--allow-lists),
[default-allow-lists/kubelet.yaml](./default-allow-lists/kubelet.yaml).

### cAdvisor

[cAdvisor](https://github.com/google/cadvisor) metrics gather information about containers on each node.

The cAdvisor metric source uses an [allow list](#metrics-tuning--allow-lists),
[default-allow-lists/cadvisor.yaml](./default-allow-lists/cadvisor.yaml).

### API Server

API Server metrics gather information about the Kubernetes API Server.

### Kube Controller Manager

Kube Controller Manager metrics gather information about the Kubernetes Controller Manager.

### Kube Proxy

Kube Proxy metrics gather information about the Kubernetes Proxy.

### Kube Scheduler

Kube Scheduler metrics gather information about the Kubernetes Scheduler.

### kube-state-metrics

[kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) metrics gather information about Kubernetes
resources inside the cluster.

The kube-state-metrics metric source uses an [allow list](#metrics-tuning--allow-lists),
[default-allow-lists/kube-state-metrics.yaml](./default-allow-lists/kube-state-metrics.yaml).

### Node Exporter

[Node Exporter](https://github.com/prometheus/node_exporter) metrics gather information about Linux Kubernetes Nodes.

The Node Exporter metric source uses an [allow list](#metrics-tuning--allow-lists),
[default-allow-lists/node-exporter.yaml](./default-allow-lists/node-exporter.yaml), and has an integration allow list,
[default-allow-lists/node-exporter-integration.yaml](./default-allow-lists/node-exporter-integration.yaml).

### Windows Exporter

[Windows Exporter](https://github.com/prometheus-community/windows_exporter) metrics gather information about Windows
Kubernetes Nodes.

The Windows Exporter metric source uses an [allow list](#metrics-tuning--allow-lists),
[default-allow-lists/windows-exporter.yaml](./default-allow-lists/windows-exporter.yaml).

### Kepler

[Kepler](https://sustainable-computing.io/) metrics gather information about the Kubernetes cluster.

The Kepler metric source uses an [allow list](#metrics-tuning--allow-lists),
[default-allow-lists/kepler.yaml](./default-allow-lists/kepler.yaml).

## Metrics Tuning & Allow Lists

All metric sources have the ability to adjust the amount of metrics being scraped and their labels. This can be useful
to limit the number of metrics delivered to your destinations. Many of the metric sources also have an allow list, which
is a set of metric names that will be kept, while any metrics not on the list will be dropped. The allow lists are tuned
to return a useful, but minimal set of metrics for typical use cases. Some sources have an "integration allow list",
which contains even more metrics for diving into the details of the source itself.

To control these settings, use the `metricsTuning` section in the values file.

```yaml
<metric source>:
  metricsTuning:
    useDefaultAllowList: <boolean>      # Use the allow list for this metric source
    useIntegrationAllowList: <boolean>  # Use the integration allow list for this metric source
    includeMetrics: [<string>]          # Metrics to be kept
    excludeMetrics: [<string>]          # Metrics to be dropped
```

The behavior of the combination of these settings is shown in this table:

| Allow List | includeMetrics   | excludeMetrics           | Result                                                                                                                                  |
|------------|------------------|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| true       | `[]`             | `[]`                     | Use the allow list metric list                                                                                                          |
| false      | `[]`             | `[]`                     | No filter, keep all metrics                                                                                                             |
| true       | `[my_metric]`    | `[]`                     | Use the allow list metric list with an additional metric                                                                                |
| false      | `[my_metric_.*]` | `[]`                     | *Only* keep metrics that start with `my_metric_`                                                                                        |
| true       | `[]`             | `[my_metric_.*]`         | Use the allow list metric filter, but exclude anything that starts with `my_metric_`                                                    |
| false      | `[]`             | `[my_metric_.*]`         | Keep all metrics except anything that starts with `my_metric_`                                                                          |
| true       | `[my_metric_.*]` | `[other_metric_.*]`      | Use the allow list metric filter, and keep anything that starts with `my_metric_`, but remove anything that starts with `other_metric_` |
| false      | `[my_metric_.*]` | `[my_metric_not_needed]` | *Only* keep metrics that start with `my_metric_`, but remove any that are named `my_metric_not_needed`                                  |

In addition to all fo this, you can also use the `extraMetricProcessingRules` section to add arbitrary relabeling rules that can be used to take any
action on the metric list, including filtering based on label or other actions.

## Testing

This chart contains unit tests to verify the generated configuration. A hidden value, `deployAsConfigMap`, will render
the generated configuration into a ConfigMap object. This ConfigMap is not used during regular operation, but it is
useful for showing the outcome of a given values file.

The unit tests use this to create an object with the configuration that can be asserted against. To run the tests, use
`helm test`.

Actual integration testing in a live environment should be done in the main [k8s-monitoring](../k8s-monitoring) chart.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |

<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-cluster-metrics>
<!-- markdownlint-enable list-marker-space -->

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 5.26.0 |
| https://prometheus-community.github.io/helm-charts | node-exporter(prometheus-node-exporter) | 4.42.0 |
| https://prometheus-community.github.io/helm-charts | windows-exporter(prometheus-windows-exporter) | 0.5.1 |
| https://sustainable-computing-io.github.io/kepler-helm-chart | kepler | 0.5.11 |
<!-- markdownlint-enable no-bare-urls -->

<!-- markdownlint-disable no-space-in-emphasis -->
## Values

### API Server

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| apiServer.enabled | bool | `false` | Scrape metrics from the API Server. |
| apiServer.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the API Server. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| apiServer.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the API Server. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| apiServer.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| apiServer.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| apiServer.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| apiServer.scrapeInterval | string | 60s | How frequently to scrape metrics from the API Server Overrides metrics.scrapeInterval |

### cAdvisor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cadvisor.enabled | bool | `true` | Scrape metrics from cAdvisor. |
| cadvisor.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for cAdvisor entities. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| cadvisor.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for cAdvisor metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| cadvisor.maxCacheSize | string | `100000` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| cadvisor.metricsTuning.dropEmptyContainerLabels | bool | `true` | Drop metrics that have an empty container label |
| cadvisor.metricsTuning.dropEmptyImageLabels | bool | `true` | Drop metrics that have an empty image label |
| cadvisor.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| cadvisor.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| cadvisor.metricsTuning.keepPhysicalFilesystemDevices | list | `["mmcblk.p.+","nvme.+","rbd.+","sd.+","vd.+","xvd.+","dasd.+"]` | Only keep filesystem metrics that use the following physical devices |
| cadvisor.metricsTuning.keepPhysicalNetworkDevices | list | `["en[ospx][0-9].*","wlan[0-9].*","eth[0-9].*"]` | Only keep network metrics that use the following physical devices |
| cadvisor.metricsTuning.normalizeUnnecessaryLabels | list | `[{"labels":["boot_id","system_uuid"],"metric":"machine_memory_bytes"}]` | Normalize labels to the same value for the given metric and label pairs |
| cadvisor.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from cAdvisor to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |

### cadvisor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cadvisor.scrapeInterval | string | `60s` | How frequently to scrape cAdvisor metrics. |

### Control Plane

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controlPlane.enabled | bool | `false` | enable all Kubernetes Control Plane metrics sources. This includes api-server, kube-scheduler, kube-controller-manager, and etcd. |

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.alloyModules.branch | string | `"main"` | If using git, the branch of the git repository to use. |
| global.alloyModules.source | string | `"git"` | The source of the Alloy modules. The valid options are "configMap" or "git" |
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |

### Kepler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kepler.enabled | bool | `false` | Deploy and scrape Kepler metrics. |
| kepler.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kepler. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kepler.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kepler. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no __meta* labels are present. |
| kepler.labelMatchers | object | `{"app.kubernetes.io/name":"kepler"}` | Label matchers used to select the Kepler pods |
| kepler.maxCacheSize | string | `100000` | Sets the max_cache_size for the prometheus.relabel component for Kepler. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| kepler.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kepler.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| kepler.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kepler to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| kepler.scrapeInterval | string | `60s` | How frequently to scrape metrics from Kepler. Overrides global.scrapeInterval. |

### kube-state-metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-state-metrics.deploy | bool | `true` | Deploy kube-state-metrics. Set to false if your cluster already has kube-state-metrics deployed. |
| kube-state-metrics.enabled | bool | `true` | Scrape metrics from kube-state-metrics. |
| kube-state-metrics.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for kube-state-metrics. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kube-state-metrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for kube-state-metrics metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kube-state-metrics.labelMatchers | object | `{"app.kubernetes.io/name":"kube-state-metrics"}` | Labels used to select the kube-state-metrics service. |
| kube-state-metrics.maxCacheSize | string | `100000` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| kube-state-metrics.metricLabelsAllowlist | list | `["nodes=[agentpool,alpha.eksctl.io/cluster-name,alpha.eksctl.io/nodegroup-name,beta.kubernetes.io/instance-type,cloud.google.com/gke-nodepool,cluster_name,ec2_amazonaws_com_Name,ec2_amazonaws_com_aws_autoscaling_groupName,ec2_amazonaws_com_aws_autoscaling_group_name,ec2_amazonaws_com_name,eks_amazonaws_com_nodegroup,k8s_io_cloud_provider_aws,karpenter.sh/nodepool,kubernetes.azure.com/cluster,kubernetes.io/arch,kubernetes.io/hostname,kubernetes.io/os,node.kubernetes.io/instance-type,topology.kubernetes.io/region,topology.kubernetes.io/zone]"]` | `kube_<resource>_labels` metrics to generate. The default is to include a useful set for Node labels. |
| kube-state-metrics.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kube-state-metrics.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| kube-state-metrics.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kube State Metrics to a useful, minimal set. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| kube-state-metrics.scrapeInterval | string | `60s` | How frequently to scrape kube-state-metrics metrics. |

### Kube Controller Manager

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeControllerManager.enabled | bool | `false` | Scrape metrics from the Kube Controller Manager |
| kubeControllerManager.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Controller Manager. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeControllerManager.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Controller Manager. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeControllerManager.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| kubeControllerManager.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeControllerManager.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| kubeControllerManager.port | int | `10257` | Port number used by the Kube Controller Manager, set by `--secure-port.` |
| kubeControllerManager.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Controller Manager Overrides metrics.scrapeInterval |

### Kube Proxy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeProxy.enabled | bool | `false` | Scrape metrics from the Kube Proxy |
| kubeProxy.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Proxy. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeProxy.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Proxy. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeProxy.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| kubeProxy.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeProxy.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| kubeProxy.port | int | `10249` | Port number used by the Kube Proxy, set in `--metrics-bind-address`. |
| kubeProxy.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Proxy Overrides metrics.scrapeInterval |

### Kube Scheduler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeScheduler.enabled | bool | `false` | Scrape metrics from the Kube Scheduler |
| kubeScheduler.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Scheduler. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeScheduler.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Scheduler. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeScheduler.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| kubeScheduler.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeScheduler.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| kubeScheduler.port | int | `10259` | Port number used by the Kube Scheduler, set by `--secure-port`. |
| kubeScheduler.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Scheduler Overrides metrics.scrapeInterval |

### Kubelet

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubelet.enabled | bool | `true` | Scrape metrics from kubelet. |
| kubelet.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kubelet entities. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubelet.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kubelet metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubelet.maxCacheSize | string | `100000` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| kubelet.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubelet.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| kubelet.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from the Kubelet to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| kubelet.scrapeInterval | string | `60s` | How frequently to scrape Kubelet metrics. |

### Kubelet Resources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeletResource.enabled | bool | `true` | Scrape resource metrics from kubelet. |
| kubeletResource.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kubelet Resources entities. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| kubeletResource.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kubelet Resources metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| kubeletResource.maxCacheSize | string | `100000` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| kubeletResource.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| kubeletResource.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| kubeletResource.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of resources metrics from the Kubelet to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| kubeletResource.scrapeInterval | string | `60s` | How frequently to scrape Kubelet Resource metrics. |

### Node Exporter - Deployment settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| node-exporter.deploy | bool | `true` | Deploy Node Exporter. Set to false if your cluster already has Node Exporter deployed. |

### Node Exporter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| node-exporter.enabled | bool | `true` | Scrape metrics from Node Exporter. |
| node-exporter.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Node Exporter. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| node-exporter.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Node Exporter metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| node-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"node-exporter"}` | Labels used to select the Node Exporter pods. |
| node-exporter.maxCacheSize | string | `100000` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| node-exporter.metricsTuning.dropMetricsForFilesystem | list | `["tempfs"]` | Drop metrics for the given filesystem types |
| node-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| node-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| node-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| node-exporter.metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring as well as the Node Exporter integration. |
| node-exporter.scrapeInterval | string | `60s` | How frequently to scrape Node Exporter metrics. |

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
| windows-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"windows-exporter"}` | Labels used to select the Windows Exporter pods. |
| windows-exporter.maxCacheSize | string | `100000` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| windows-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| windows-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| windows-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Windows Exporter to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| windows-exporter.scrapeInterval | string | `60s` | How frequently to scrape metrics from Windows Exporter. |
<!-- markdownlint-enable no-space-in-emphasis -->
