[comment]: <> (NOTE: Do not edit README.md directly. It is a generated file!)
[comment]: <> (      To make changes, please modify README.md.gotmpl and run `helm-docs`)

# k8s-monitoring

![Version: 0.10.3](https://img.shields.io/badge/Version-0.10.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.0.2](https://img.shields.io/badge/AppVersion-2.0.2-informational?style=flat-square)

A Helm chart for gathering, scraping, and forwarding Kubernetes infrastructure metrics and logs to a Grafana Stack.

## Breaking change announcements

### **v0.9.0**

  Additional metric tuning rules have been made available for all metric sources. This means the removal of the
  `.allowList` fields from each metric source. If you have set custom allow lists for a metric source, you will need to
  make those changes in the new `.metricsTuning` section.

  The default allow list remains in place, but it's toggled with `.metricsTuning.useDefaultAllowList`.

  If you've added more metrics to the default allow list, put those additional metrics in the
  `.metricsTuning.includeMetrics` section.

  If you've removed metrics from the default allow list, put the *metrics to remove* in the
  `.metricsTuning.excludeMetrics` section.

  For more information, see [this example](../../examples/custom-metrics-tuning).

### **v0.7.0**

  The OTLP, OTLPHTTP, and Zipkin receiver definitions under `traces.receivers` has been moved up a level to `receivers`.
  This is because receivers will be able to ingest more than just traces going forward.
  Also, receivers are enabled by default, so you will likely not need to make changes to your values file other than
  removing `.traces.receivers`.

### **v0.3.0**

  The component `prometheus.remote_write.grafana_cloud_prometheus` has been renamed.
  When forwarding metrics to be sent to your metrics service endpoint, please use `prometheus.relabel.metrics_service` instead.
  This component will "fan-in" all of the metric sources to the correct metrics service.

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
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: "67890"
      password: "It's a secret to everyone"
EOF
helm install my-release grafana/k8s-monitoring --values values.yaml
```

This chart simplifies the deployment of a Kubernetes monitoring infrastructure, including the following:

* [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics), which gathers metrics about Kubernetes objects
* [Node exporter](https://github.com/prometheus/node_exporter), which gathers metrics about Kubernetes nodes
* [OpenCost](https://www.opencost.io/), which interprets the above to create cost metrics for the cluster, and
* [Grafana Agent](https://grafana.com/docs/agent/latest/), which scrapes the above services to forward metrics to [Prometheus](https://prometheus.io/), logs and events to [Loki](https://grafana.com/oss/loki/), and traces to [Tempo](https://grafana.com/oss/tempo/).

The Prometheus and Loki services may be hosted on the same cluster, or remotely (e.g. on Grafana Cloud).

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
| skl | <stephen.lang@grafana.com> |  |

## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://grafana.github.io/helm-charts | grafana-agent | 0.32.0 |
| https://grafana.github.io/helm-charts | grafana-agent-events(grafana-agent) | 0.32.0 |
| https://grafana.github.io/helm-charts | grafana-agent-logs(grafana-agent) | 0.32.0 |
| https://opencost.github.io/opencost-helm-chart | opencost | 1.28.0 |
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 5.15.3 |
| https://prometheus-community.github.io/helm-charts | prometheus-node-exporter | 4.25.0 |
| https://prometheus-community.github.io/helm-charts | prometheus-operator-crds | 8.0.1 |
| https://prometheus-community.github.io/helm-charts | prometheus-windows-exporter | 0.1.2 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cluster.kubernetesAPIService | string | `"kubernetes.default.svc.cluster.local:443"` | The Kubernetes service. Change this if your cluster DNS is configured differently than the default. |
| cluster.name | string | `""` | The name of this cluster, which will be set in all labels. Required. |
| cluster.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |
| configValidator.extraAnnotations | object | `{}` | Extra annotations to add to the test config validator job. |
| configValidator.extraLabels | object | `{}` | Extra labels to add to the test config validator job. |
| configValidator.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | nodeSelector to apply to the config validator job. |
| configValidator.tolerations | list | `[]` | Tolerations to apply to the config validator job. |
| externalServices.loki.authMode | string | `"basic"` | one of "none", "basic" |
| externalServices.loki.basicAuth.password | string | `""` | Loki basic auth password |
| externalServices.loki.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret |
| externalServices.loki.basicAuth.username | string | `""` | Loki basic auth username |
| externalServices.loki.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret |
| externalServices.loki.externalLabels | object | `{}` | Custom labels to be added to all logs and events |
| externalServices.loki.host | string | `""` | Loki host where logs and events will be sent |
| externalServices.loki.hostKey | string | `"host"` | The key for the host property in the secret |
| externalServices.loki.proxyURL | string | `""` | HTTP proxy to proxy requests to Loki through. |
| externalServices.loki.queryEndpoint | string | `"/loki/api/v1/query"` | Loki logs query endpoint. |
| externalServices.loki.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. |
| externalServices.loki.secret.name | string | `""` | The name of the secret. |
| externalServices.loki.secret.namespace | string | `""` | The namespace of the secret. |
| externalServices.loki.tenantId | string | `""` | Loki tenant ID |
| externalServices.loki.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret |
| externalServices.loki.tls | object | `{}` | [TLS settings](https://grafana.com/docs/agent/latest/flow/reference/components/loki.write/#tls_config-block) to configure for the logs service. |
| externalServices.loki.writeEndpoint | string | `"/loki/api/v1/push"` | Loki logs write endpoint. |
| externalServices.prometheus.authMode | string | `"basic"` | one of "none", "basic" |
| externalServices.prometheus.basicAuth.password | string | `""` | Prometheus basic auth password |
| externalServices.prometheus.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret |
| externalServices.prometheus.basicAuth.username | string | `""` | Prometheus basic auth username |
| externalServices.prometheus.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret |
| externalServices.prometheus.externalLabels | object | `{}` | Custom labels to be added to all time series |
| externalServices.prometheus.host | string | `""` | Prometheus host where metrics will be sent |
| externalServices.prometheus.hostKey | string | `"host"` | The key for the host property in the secret |
| externalServices.prometheus.processors.batch.maxSize | int | `0` | Upper limit of a batch size. When set to 0, there is no upper limit. |
| externalServices.prometheus.processors.batch.size | int | `8192` | Amount of data to buffer before flushing the batch. |
| externalServices.prometheus.processors.batch.timeout | string | `"2s"` | How long to wait before flushing the batch. |
| externalServices.prometheus.processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. |
| externalServices.prometheus.processors.memoryLimiter.enabled | bool | `false` | Use a memory limiter. |
| externalServices.prometheus.processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. |
| externalServices.prometheus.protocol | string | `"remote_write"` | The type of server protocol for writing metrics. Valid options:  "remote_write" will use Prometheus Remote Write,  "otlp" will use OTLP,  "otlphttp" will use OTLP HTTP |
| externalServices.prometheus.proxyURL | string | `""` | HTTP proxy to proxy requests to Prometheus through. |
| externalServices.prometheus.queryEndpoint | string | `"/api/prom/api/v1/query"` | Prometheus metrics query endpoint. Preset for Grafana Cloud Metrics instances. |
| externalServices.prometheus.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. |
| externalServices.prometheus.secret.name | string | `""` | The name of the secret. |
| externalServices.prometheus.secret.namespace | string | `""` | The namespace of the secret. Only used if secret.create = "false" |
| externalServices.prometheus.tenantId | string | `""` | Sets the `X-Scope-OrgID` header when sending metrics |
| externalServices.prometheus.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret |
| externalServices.prometheus.tls | object | `{}` | TLS settings to configure for the metrics service, compatible with [remoteWrite protocol](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.remote_write/#tls_config-block), [otlp](https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.exporter.otlp/#tls-block), or [otlphttp](https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.exporter.otlphttp/#tls-block) protocols |
| externalServices.prometheus.wal.maxKeepaliveTime | string | `"8h"` | Maximum time to keep data in the WAL before removing it. |
| externalServices.prometheus.wal.minKeepaliveTime | string | `"5m"` | Minimum time to keep data in the WAL before it can be removed. |
| externalServices.prometheus.wal.truncateFrequency | string | `"2h"` | How frequently to clean up the WAL. |
| externalServices.prometheus.writeEndpoint | string | `"/api/prom/push"` | Prometheus metrics write endpoint. Preset for Grafana Cloud Metrics instances. |
| externalServices.prometheus.writeRelabelConfigRules | string | `""` | Rule blocks to be added to the [write_relabel_config block](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.remote_write/#write_relabel_config-block) of the prometheus.remote_write component. |
| externalServices.tempo.authMode | string | `"basic"` | one of "none", "basic" |
| externalServices.tempo.basicAuth.password | string | `""` | Tempo basic auth password |
| externalServices.tempo.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret |
| externalServices.tempo.basicAuth.username | string | `""` | Tempo basic auth username |
| externalServices.tempo.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret |
| externalServices.tempo.host | string | `""` | Tempo host where traces will be sent |
| externalServices.tempo.hostKey | string | `"host"` | The key for the host property in the secret |
| externalServices.tempo.protocol | string | `"otlp"` | The type of server protocol for writing metrics Options:   * "otlp" will use OTLP   * "otlphttp" will use OTLP HTTP |
| externalServices.tempo.searchEndpoint | string | `"/api/search"` | Tempo search endpoint. |
| externalServices.tempo.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. |
| externalServices.tempo.secret.name | string | `""` | The name of the secret. |
| externalServices.tempo.secret.namespace | string | `""` | The namespace of the secret. |
| externalServices.tempo.tenantId | string | `""` | Tempo tenant ID |
| externalServices.tempo.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret |
| externalServices.tempo.tls | object | `{}` | [TLS settings](https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.exporter.otlp/#tls-block) to configure for the traces service. |
| externalServices.tempo.tlsOptions | string | `""` | Define the [TLS block](https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.exporter.otlp/#tls-block). Example: `tlsOptions: insecure = true` This option will be deprecated and removed soon. Please switch to `tls` and use yaml format. |
| extraConfig | string | `""` | Extra configuration that will be added to Grafana Agent configuration file. This cannot be used to modify the generated configuration values, only append new components. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example. |
| extraObjects | list | `[]` | Deploy additional manifest objects |
| global.image.pullSecrets | list | `[]` | Optional set of global image pull secrets. |
| global.image.registry | string | `""` | Global image registry to use if it needs to be overriden for some specific use cases (e.g local registries, custom images, ...) |
| kube-state-metrics.enabled | bool | `true` | Should this helm chart deploy Kube State Metrics to the cluster. Set this to false if your cluster already has Kube State Metrics, or if you do not want to scrape metrics from Kube State Metrics. |
| logs.cluster_events.enabled | bool | `true` | Scrape Kubernetes cluster events |
| logs.cluster_events.logFormat | string | `"logfmt"` | Log format used to forward cluster events. Allowed values: `logfmt` (default), `json`. |
| logs.cluster_events.namespaces | list | `[]` | List of namespaces to watch for events (`[]` means all namespaces) |
| logs.enabled | bool | `true` | Capture and forward logs |
| logs.extraConfig | string | `""` | Extra configuration that will be added to Grafana Agent Logs configuration file. This cannot be used to modify the generated configuration values, only append new components. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example. |
| logs.pod_logs.annotation | string | `"k8s.grafana.com/logs.autogather"` | Pod annotation to use for controlling log discovery. |
| logs.pod_logs.discovery | string | `"all"` | Controls the behavior of discovering pods for logs. |
| logs.pod_logs.enabled | bool | `true` | Capture and forward logs from Kubernetes pods |
| logs.pod_logs.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for pod logs. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| logs.pod_logs.extraStageBlocks | string | `""` | Stage blocks to be added to the loki.process component for pod logs. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/loki.process/#blocks)) |
| logs.pod_logs.gatherMethod | string | `"volumes"` | Controls the behavior of gathering pod logs. When set to "volumes", the Grafana Agent will use HostPath volume mounts on the cluster nodes to access the pod log files directly. When set to "api", the Grafana Agent will access pod logs via the API server. This method may be preferable if your cluster prevents DaemonSets, HostPath volume mounts, or for other reasons. |
| logs.pod_logs.namespaces | list | `[]` | Only capture logs from pods in these namespaces (`[]` means all namespaces) |
| logs.receiver.filters | object | `{"log_record":[]}` | Apply a filter to logs received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.processor.filter/)) |
| metrics.agent.enabled | bool | `true` | Scrape metrics from Grafana Agent |
| metrics.agent.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Grafana Agent. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.agent.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Grafana Agent. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.agent.labelMatchers | object | `{"app.kubernetes.io/name":"grafana-agent.*"}` | Label matchers used by the Grafana Agent to select Grafana Agent pods |
| metrics.agent.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.agent.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. |
| metrics.agent.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from the Grafana Agent to the minimal set required for Kubernetes Monitoring. See [Allow List for Grafana Agent](#allow-list-for-grafana-agent) |
| metrics.agent.metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from the Grafana Agent to the minimal set required for Kubernetes Monitoring as well as the Grafana Agent integration. |
| metrics.agent.scrapeInterval | string | 60s | How frequently to scrape metrics from Grafana Agent. Overrides metrics.scrapeInterval |
| metrics.apiserver.enabled | bool | `false` | Scrape metrics from the API Server |
| metrics.apiserver.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the API Server. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.apiserver.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the API Server. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.apiserver.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.apiserver.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. An empty list means keep all. |
| metrics.apiserver.scrapeInterval | string | 60s | How frequently to scrape metrics from the API Server Overrides metrics.scrapeInterval |
| metrics.autoDiscover.annotations.instance | string | `"k8s.grafana.com/instance"` | Annotation for overriding the instance label |
| metrics.autoDiscover.annotations.job | string | `"k8s.grafana.com/job"` | Annotation for overriding the job label |
| metrics.autoDiscover.annotations.metricsPath | string | `"k8s.grafana.com/metrics.path"` | Annotation for setting or overriding the metrics path. If not set, it defaults to /metrics |
| metrics.autoDiscover.annotations.metricsPortName | string | `"k8s.grafana.com/metrics.portName"` | Annotation for setting the metrics port by name. |
| metrics.autoDiscover.annotations.metricsPortNumber | string | `"k8s.grafana.com/metrics.portNumber"` | Annotation for setting the metrics port by number. |
| metrics.autoDiscover.annotations.metricsScheme | string | `"k8s.grafana.com/metrics.scheme"` | Annotation for setting the metrics scheme, default: http. |
| metrics.autoDiscover.annotations.scrape | string | `"k8s.grafana.com/scrape"` | Annotation for enabling scraping for this service or pod. Value should be either "true" or "false" |
| metrics.autoDiscover.enabled | bool | `true` | Enable annotation-based autodiscovery |
| metrics.autoDiscover.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for auto-discovered entities. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.autoDiscover.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for auto-discovered entities. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.autoDiscover.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.autoDiscover.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. An empty list means keep all. |
| metrics.cadvisor.enabled | bool | `true` | Scrape container metrics from cAdvisor |
| metrics.cadvisor.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for cAdvisor. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.cadvisor.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for cAdvisor. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.cadvisor.metricsTuning.dropEmptyContainerLabels | bool | `true` | Drop metrics that have an empty container label |
| metrics.cadvisor.metricsTuning.dropEmptyImageLabels | bool | `true` | Drop metrics that have an empty image label |
| metrics.cadvisor.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.cadvisor.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. |
| metrics.cadvisor.metricsTuning.keepPhysicalFilesystemDevices | list | `["mmcblk.p.+","nvme.+","rbd.+","sd.+","vd.+","xvd.+","dasd.+"]` | Only keep filesystem metrics that use the following physical devices |
| metrics.cadvisor.metricsTuning.keepPhysicalNetworkDevices | list | `["en[ospx][0-9].*","wlan[0-9].*","eth[0-9].*"]` | Only keep network metrics that use the following physical devices |
| metrics.cadvisor.metricsTuning.normalizeUnnecessaryLabels | list | `[{"labels":["boot_id","system_uuid"],"metric":"machine_memory_bytes"}]` | Normalize labels to the same value for the given metric and label pairs |
| metrics.cadvisor.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from cAdvisor to the minimal set required for Kubernetes Monitoring. See [Allow List for cAdvisor](#allow-list-for-cadvisor) |
| metrics.cadvisor.nodeAddressFormat | string | `"direct"` | How to access the node services, either direct (use node IP, requires nodes/metrics) or via proxy (requires nodes/proxy) |
| metrics.cadvisor.scrapeInterval | string | 60s | How frequently to scrape metrics from cAdvisor. Overrides metrics.scrapeInterval |
| metrics.cost.enabled | bool | `true` | Scrape cost metrics from OpenCost |
| metrics.cost.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for OpenCost. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.cost.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for OpenCost. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.cost.labelMatchers | object | `{"app.kubernetes.io/name":"opencost"}` | Label matchers used by the Grafana Agent to select the OpenCost service |
| metrics.cost.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.cost.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. |
| metrics.cost.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from OpenCost to the minimal set required for Kubernetes Monitoring. See [Allow List for OpenCost](#allow-list-for-opencost) |
| metrics.cost.scrapeInterval | string | 60s | How frequently to scrape metrics from OpenCost. Overrides metrics.scrapeInterval |
| metrics.enabled | bool | `true` | Capture and forward metrics |
| metrics.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for all metric sources. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for all metric sources. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.kube-state-metrics.enabled | bool | `true` | Scrape cluster object metrics from Kube State Metrics |
| metrics.kube-state-metrics.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kube State Metrics. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kube-state-metrics.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kube State Metrics. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.kube-state-metrics.labelMatchers | object | `{"app.kubernetes.io/name":"kube-state-metrics"}` | Label matchers used by the Grafana Agent to select the Kube State Metrics service |
| metrics.kube-state-metrics.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.kube-state-metrics.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. |
| metrics.kube-state-metrics.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kube State Metrics to a useful, minimal set. See [Allow List for Kube State Metrics](#allow-list-for-kube-state-metrics) |
| metrics.kube-state-metrics.scrapeInterval | string | 60s | How frequently to scrape metrics from Kube State Metrics. Overrides metrics.scrapeInterval |
| metrics.kube-state-metrics.service.isTLS | bool | `false` | Does this port use TLS? |
| metrics.kube-state-metrics.service.port | string | `"http"` | Name of the metrics port |
| metrics.kubeControllerManager.enabled | bool | `false` | Scrape metrics from the Kube Controller Manager |
| metrics.kubeControllerManager.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Controller Manager. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kubeControllerManager.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Controller Manager. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.kubeControllerManager.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.kubeControllerManager.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. An empty list means keep all. |
| metrics.kubeControllerManager.port | int | `10257` |  |
| metrics.kubeControllerManager.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Controller Manager Overrides metrics.scrapeInterval |
| metrics.kubeProxy.enabled | bool | `false` | Scrape metrics from the Kube Proxy |
| metrics.kubeProxy.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Proxy. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kubeProxy.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Proxy. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.kubeProxy.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.kubeProxy.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. An empty list means keep all. |
| metrics.kubeProxy.port | int | `10249` |  |
| metrics.kubeProxy.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Proxy Overrides metrics.scrapeInterval |
| metrics.kubeScheduler.enabled | bool | `false` | Scrape metrics from the Kube Scheduler |
| metrics.kubeScheduler.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Scheduler. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kubeScheduler.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Scheduler. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.kubeScheduler.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.kubeScheduler.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. An empty list means keep all. |
| metrics.kubeScheduler.port | int | `10259` |  |
| metrics.kubeScheduler.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Scheduler Overrides metrics.scrapeInterval |
| metrics.kubelet.enabled | bool | `true` | Scrape cluster metrics from the Kubelet |
| metrics.kubelet.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kubelet. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kubelet.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kubelet. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.kubelet.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.kubelet.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. |
| metrics.kubelet.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from the Kubelet to the minimal set required for Kubernetes Monitoring. See [Allow List for Kubelet](#allow-list-for-kubelet) |
| metrics.kubelet.nodeAddressFormat | string | `"direct"` | How to access the node services, either direct (use node IP, requires nodes/metrics) or via proxy (requires nodes/proxy) |
| metrics.kubelet.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kubelet. Overrides metrics.scrapeInterval |
| metrics.kubernetesMonitoring.enabled | bool | `true` | Report telemetry about this Kubernetes Monitoring chart as a metric. |
| metrics.node-exporter.enabled | bool | `true` | Scrape node metrics |
| metrics.node-exporter.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Node Exporter. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.node-exporter.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Node Exporter. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.node-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"prometheus-node-exporter.*"}` | Label matchers used by the Grafana Agent to select the Node exporter pods |
| metrics.node-exporter.metricsTuning.dropMetricsForFilesystem | list | `["tempfs"]` | Drop metrics for the given filesystem types |
| metrics.node-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.node-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. |
| metrics.node-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring. See [Allow List for Node Exporter](#allow-list-for-node-exporter) |
| metrics.node-exporter.metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring as well as the Node Exporter integration. |
| metrics.node-exporter.scrapeInterval | string | 60s | How frequently to scrape metrics from Node Exporter. Overrides metrics.scrapeInterval |
| metrics.node-exporter.service.isTLS | bool | `false` | Does this port use TLS? |
| metrics.podMonitors.enabled | bool | `true` | Include service discovery for PodMonitor objects |
| metrics.podMonitors.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for PodMonitor objects. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.podMonitors.namespaces | list | `[]` | Which namespaces to look for PodMonitor objects. |
| metrics.podMonitors.scrapeInterval | string | 60s | How frequently to scrape metrics from PodMonitor objects. Only used if the PodMonitor does not specify the scrape interval. Overrides metrics.scrapeInterval |
| metrics.probes.enabled | bool | `true` | Include service discovery for Probe objects. |
| metrics.probes.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Probe objects. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.probes.namespaces | list | `[]` | Which namespaces to look for Probe objects. |
| metrics.probes.scrapeInterval | string | 60s | How frequently to scrape metrics from Probe objects. Only used if the Probe does not specify the scrape interval. Overrides metrics.scrapeInterval |
| metrics.receiver.filters | object | `{"datapoint":[],"metric":[]}` | Apply a filter to metrics received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.processor.filter/)) |
| metrics.scrapeInterval | string | `"60s"` | How frequently to scrape metrics |
| metrics.serviceMonitors.enabled | bool | `true` | Include service discovery for ServiceMonitor objects |
| metrics.serviceMonitors.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for ServiceMonitor objects. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.serviceMonitors.namespaces | list | `[]` | Which namespaces to look for ServiceMonitor objects. |
| metrics.serviceMonitors.scrapeInterval | string | 60s | How frequently to scrape metrics from ServiceMonitor objects. Only used if the ServiceMonitor does not specify the scrape interval. Overrides metrics.scrapeInterval |
| metrics.windows-exporter.enabled | bool | `false` | Scrape node metrics |
| metrics.windows-exporter.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Windows Exporter. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/#rule-block)) |
| metrics.windows-exporter.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Windows Exporter. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/#rule-block)) |
| metrics.windows-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"prometheus-windows-exporter.*"}` | Label matchers used by the Grafana Agent to select the Windows Exporter pods |
| metrics.windows-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regex. |
| metrics.windows-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regex. |
| metrics.windows-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Windows Exporter to the minimal set required for Kubernetes Monitoring. See [Allow List for Windows Exporter](#allow-list-for-windows-exporter) |
| metrics.windows-exporter.scrapeInterval | string | 60s | How frequently to scrape metrics from Windows Exporter. Overrides metrics.scrapeInterval |
| opencost.enabled | bool | `true` | Should this Helm chart deploy OpenCost to the cluster. Set this to false if your cluster already has OpenCost, or if you do not want to scrape metrics from OpenCost. |
| opencost.opencost.prometheus.external.url | string | `"https://prom.example.com/api/prom"` | The URL for Prometheus queries. It should match externalService.prometheus.host + "/api/prom" |
| opencost.opencost.prometheus.password_key | string | `"password"` | The key for the password property in the secret. |
| opencost.opencost.prometheus.secret_name | string | `"prometheus-k8s-monitoring"` | The name of the secret containing the username and password for the metrics service. This must be in the same namespace as the OpenCost deployment. |
| opencost.opencost.prometheus.username_key | string | `"username"` | The key for the username property in the secret. |
| prometheus-node-exporter.enabled | bool | `true` | Should this helm chart deploy Node Exporter to the cluster. Set this to false if your cluster already has Node Exporter, or if you do not want to scrape metrics from Node Exporter. |
| prometheus-operator-crds.enabled | bool | `true` | Should this helm chart deploy the Prometheus Operator CRDs to the cluster. Set this to false if your cluster already has the CRDs, or if you do not to have the Grafana Agent scrape metrics from PodMonitors, Probes, or ServiceMonitors. |
| prometheus-windows-exporter.config | string | `"collectors:\n  enabled: cpu,cs,container,logical_disk,memory,net,os\ncollector:\n  service:\n    services-where: \"Name='containerd' or Name='kubelet'\""` | Windows Exporter configuration |
| prometheus-windows-exporter.enabled | bool | `false` | Should this helm chart deploy Windows Exporter to the cluster. Set this to false if your cluster already has Windows Exporter, or if you do not want to scrape metrics from Windows Exporter. |
| receivers.grpc.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. |
| receivers.grpc.enabled | bool | `true` | Receive OpenTelemetry signals over OTLP/gRPC? |
| receivers.grpc.port | int | `4317` | Which port to use for the OTLP/gRPC receiver. This port needs to be opened in the grafana-agent section below. |
| receivers.http.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. |
| receivers.http.enabled | bool | `true` | Receive OpenTelemetry signals over OTLP/HTTP? |
| receivers.http.port | int | `4318` | Which port to use for the OTLP/HTTP receiver. This port needs to be opened in the grafana-agent section below. |
| receivers.jaeger.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. |
| receivers.jaeger.grpc.enabled | bool | `false` | Receive Jaeger signals via gRPC protocol. |
| receivers.jaeger.grpc.port | int | `14250` | Which port to use for the Jaeger gRPC receiver. This port needs to be opened in the grafana-agent section below. |
| receivers.jaeger.thriftBinary.enabled | bool | `false` | Receive Jaeger signals via Thrift binary protocol. |
| receivers.jaeger.thriftBinary.port | int | `6832` | Which port to use for the Thrift binary receiver. This port needs to be opened in the grafana-agent section below. |
| receivers.jaeger.thriftCompact.enabled | bool | `false` | Receive Jaeger signals via Thrift compact protocol. |
| receivers.jaeger.thriftCompact.port | int | `6831` | Which port to use for the Thrift compact receiver. This port needs to be opened in the grafana-agent section below. |
| receivers.jaeger.thriftHttp.enabled | bool | `false` | Receive Jaeger signals via Thrift HTTP protocol. |
| receivers.jaeger.thriftHttp.port | int | `14268` | Which port to use for the Thrift HTTP receiver. This port needs to be opened in the grafana-agent section below. |
| receivers.processors.batch.maxSize | int | `0` | The upper limit of the amount of data contained in a single batch, in bytes. When set to 0, batches can be any size. |
| receivers.processors.batch.size | int | `16384` | What batch size to use, in bytes |
| receivers.processors.batch.timeout | string | `"2s"` | How long before sending |
| receivers.prometheus.enabled | bool | `false` | Receive Prometheus metrics |
| receivers.prometheus.port | int | `9999` | Which port to use for the Prometheus receiver. This port needs to be opened in the grafana-agent section below. |
| receivers.zipkin.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. |
| receivers.zipkin.enabled | bool | `false` | Receive Zipkin traces |
| receivers.zipkin.port | int | `9411` | Which port to use for the Zipkin receiver. This port needs to be opened in the grafana-agent section below. |
| test.attempts | int | `10` | How many times to attempt the test job. |
| test.envOverrides | object | `{"LOKI_URL":"","PROMETHEUS_URL":"","TEMPO_URL":""}` | Overrides the URLs for various data sources |
| test.extraAnnotations | object | `{}` | Extra annotations to add to the test jobs. |
| test.extraLabels | object | `{}` | Extra labels to add to the test jobs. |
| test.extraQueries | list | `[]` | Additional queries that will be run with `helm test`. NOTE that this uses the host, username, and password in the externalServices section. The user account must have the ability to run queries. Example: extraQueries:   - query: prometheus_metric{cluster="my-cluster-name"}     type: [promql|logql] |
| test.image.image | string | `"grafana/k8s-monitoring-test"` | Test job image repository. |
| test.image.pullSecrets | list | `[]` | Optional set of image pull secrets. |
| test.image.registry | string | `"ghcr.io"` | Test job image registry. |
| test.image.tag | string | `""` | Test job image tag. Default is the chart version. |
| test.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | nodeSelector to apply to the test job. |
| test.tolerations | list | `[]` | Tolerations to apply to the test job. |
| traces.enabled | bool | `false` | Receive and forward traces. |
| traces.receiver.filters | object | `{"span":[],"spanevent":[]}` | Apply a filter to traces received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/agent/latest/flow/reference/components/otelcol.processor.filter/)) |

## Customizing the configuration

There are several options for customizing the configuration generated by this chart. This can be used to add extra
scrape targets, for example, to [scrape metrics from an application](./docs/ScrapeApplicationMetrics.md) deployed on the
same Kubernetes cluster.

### Adding custom Flow configuration

Any value supplied to the `.extraConfig` or `.logs.extraConfig` values will be appended to the generated config file.
This can be used to add more Grafana Agent Flow components to provide extra functionality to the agent.

NOTE: This cannot be used to modify existing configuration values.

Extra flow components can re-use any of the existing components in the generated configuration, which includes several
useful ones like these:

* `discovery.kubernetes.nodes` - Discovers all nodes in the cluster
* `discovery.kubernetes.pods` - Discovers all pods in the cluster
* `discovery.kubernetes.services` - Discovers all services in the cluster
* `prometheus.relabel.metrics_service` - Sends metrics to the metrics service defined by `.externalService.prometheus`
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
    forward_to = [prometheus.relabel.metrics_service.receiver]
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

If your cluster is on OpenShift, this Helm chart can be configured to scrape metrics from the existing Kube State Metrics and Node Exporter that are deployed by [OpenShift Container Platform monitoring](https://docs.openshift.com/container-platform/latest/monitoring/monitoring-overview.html).
For the specific modifications, see the [OpenShift Compatible example](../../examples/openshift-compatible).

## Troubleshooting

If you're encountering issues deploying or using this chart, check the [Troubleshooting doc](./docs/Troubleshooting.md).

## Metrics Tuning and Allow Lists

Each metric source has the ability to adjust the amount of metrics being scraped and their labels. This can be useful to
limit the sheer number of metrics. Many of the metric sources have an allow list, which is a set of metric names that
will be kept, while any metrics not on the list will be dropped. The allow lists are tuned to return a useful, but
minimal set of metrics for Kubernetes Monitoring.

If you want to allow all metrics, set this in the values file:

```yaml
metrics:
  <metric source>:
    metricsTuning:
      useDefaultAllowList: false
```

The following sections contain the allow lists that are defined for the associated metric sources.

For more examples of metrics tuning, such as including or excluding metrics, see [this example](../../examples/custom-metrics-tuning).

### Allow List for Grafana Agent

Visit the Grafana Agent Metrics [documentation](https://grafana.com/solutions/grafana-agent/monitor/) for the full list of agent metrics

Visit the Grafana Agent Controller and Component Metrics [documentation](https://grafana.com/docs/agent/latest/flow/monitoring/) for the full list of component metrics

* agent_build_info

### Allow List for Kube State Metrics

Visit the Kube State Metrics [documentation](https://github.com/kubernetes/kube-state-metrics/tree/main/docs#exposed-metrics) for the full list of metrics

* up
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
* kube_node.*
* kube_persistentvolumeclaim_resource_requests_storage_bytes
* kube_pod_container_info
* kube_pod_container_resource_limits
* kube_pod_container_resource_requests
* kube_pod_container_status_last_terminated_reason
* kube_pod_container_status_restarts_total
* kube_pod_container_status_waiting_reason
* kube_pod_info
* kube_pod_owner
* kube_pod_start_time
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
