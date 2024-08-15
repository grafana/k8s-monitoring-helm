<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring

![Version: 1.4.7](https://img.shields.io/badge/Version-1.4.7-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.8.0](https://img.shields.io/badge/AppVersion-2.8.0-informational?style=flat-square)

A Helm chart for gathering, scraping, and forwarding Kubernetes telemetry data to a Grafana Stack.

## Breaking change announcements

### **v1.0.0**

Grafana Agent has been replaced with [Grafana Alloy](https://grafana.com/oss/alloy-opentelemetry-collector/)!

These sections in your values file will need to be renamed:

| Old                      | New              | Purpose                                                          |
|--------------------------|------------------|------------------------------------------------------------------|
| `grafana-agent`          | `alloy`          | Settings for the Alloy instance for metrics and application data |
| `grafana-agent-events`   | `alloy-events`   | Settings for the Alloy instance for Cluster events               |
| `grafana-agent-logs`     | `alloy-logs`     | Settings for the Alloy instance for Pod logs                     |
| `grafana-agent-profiles` | `alloy-profiles` | Settings for the Alloy instance for profiles                     |
| `metrics.agent`          | `metrics.alloy`  | Settings for scraping metrics from Alloy instances               |

For example, if you have something like this:

```yaml
grafana-agent:
  controller:
    replicas: 2
```

you will need to change it to this:

```yaml
alloy:
  controller:
    replicas: 2
`````

### **v0.12.0**

The component `loki.write.grafana_cloud_loki` has been renamed.
When forwarding logs to be sent to your logs service endpoint, please use `loki.process.logs_service` instead.
This component will deliver logs, no matter which protocol is used for your logs service.

### **v0.9.0**

Additional metric tuning rules have been made available for all metric sources. This means the removal of the
`.allowList` fields from each metric source. If you have set custom allow lists for a metric source, you will need to
make those changes in the new `.metricsTuning` section.

The default allow lists still apply, but they are toggled with `.metricsTuning.useDefaultAllowList`.

If you've added more metrics to the default allow list, put those additional metrics in the
`.metricsTuning.includeMetrics` section.

If you've removed metrics from the default allow list, put the *metrics to remove* in the
`.metricsTuning.excludeMetrics` section.

For more information, see [this example](../../examples/custom-metrics-tuning).

### **v0.7.0**

The OTLP, OTLPHTTP, and Zipkin receiver definitions under `traces.receivers` has been moved up a level to `receivers`.
This is because receivers will be able to ingest more than only traces going forward.
Also, receivers are enabled by default, so you will likely not need to make changes to your values file other than
removing `.traces.receivers`.

### **v0.3.0**

The component `prometheus.remote_write.grafana_cloud_prometheus` has been renamed.
When forwarding metrics to be sent to your metrics service endpoint, please use `prometheus.relabel.metrics_service` instead.
This component will "fan-in" all of the metric sources to the correct metrics service.

## Usage

### Setup Grafana chart repository

```shell
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
helm install grafana-k8s-monitoring --atomic --timeout 300s  grafana/k8s-monitoring --values values.yaml
```

This chart simplifies the deployment of a Kubernetes monitoring infrastructure, including the following:

-   [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics), which gathers metrics about Kubernetes objects
-   [Node exporter](https://github.com/prometheus/node_exporter), which gathers metrics about Kubernetes nodes
-   [OpenCost](https://www.opencost.io/), which interprets the above to create cost metrics for the cluster, and
-   [Grafana Alloy](https://grafana.com/docs/alloy/latest/), which scrapes the above services to forward metrics to
    [Prometheus](https://prometheus.io/), logs and events to [Loki](https://grafana.com/oss/loki/), traces to
    [Tempo](https://grafana.com/oss/tempo/), and profiles to [Pyroscope](https://grafana.com/docs/pyroscope/).

The Prometheus and Loki services may be hosted on the same cluster, or remotely (e.g. on Grafana Cloud).

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
| skl | <stephen.lang@grafana.com> |  |

## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring>

<!-- markdownlint-disable no-bare-urls -->
## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://grafana.github.io/helm-charts | alloy | 0.6.0 |
| https://grafana.github.io/helm-charts | alloy-events(alloy) | 0.6.0 |
| https://grafana.github.io/helm-charts | alloy-logs(alloy) | 0.6.0 |
| https://grafana.github.io/helm-charts | alloy-profiles(alloy) | 0.6.0 |
| https://opencost.github.io/opencost-helm-chart | opencost | 1.41.0 |
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 5.25.1 |
| https://prometheus-community.github.io/helm-charts | prometheus-node-exporter | 4.38.0 |
| https://prometheus-community.github.io/helm-charts | prometheus-operator-crds | 13.0.2 |
| https://prometheus-community.github.io/helm-charts | prometheus-windows-exporter | 0.3.1 |
| https://sustainable-computing-io.github.io/kepler-helm-chart | kepler | 0.5.9 |
<!-- markdownlint-enable no-bare-urls -->

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-events.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Cluster Events Deployment |
| alloy-events.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Cluster Events Deployment |
| alloy-events.logging.level | string | `"info"` | Level at which Alloy log lines should be written. @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Cluster Events Deployment |
| alloy-logs.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Logs Deployment |
| alloy-logs.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Logs Deployment |
| alloy-logs.logging.level | string | `"info"` | Level at which Alloy log lines should be written. @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Logs Deployment |
| alloy-profiles.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Profiles Deployment |
| alloy-profiles.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Profiles Deployment |
| alloy-profiles.logging.level | string | `"info"` | Level at which Alloy log lines should be written. @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Profiles Deployment |
| alloy.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) |
| alloy.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) |
| alloy.logging.level | string | `"info"` | Level at which Alloy log lines should be written. @section -- Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) |
| beyla.application | bool | `true` | Enable application observability for Beyla. Required for Application Observability. @section -- Beyla |
| beyla.debug | bool | `false` | Enable debug mode for Beyla @section -- Beyla |
| beyla.enabled | bool | `false` | Enable Beyla for automatic instrumentation eBPF in the cluster. @section -- Beyla |
| beyla.metrics | bool | `true` | Export Prometheus metrics. @section -- Beyla |
| beyla.namespaces | list | `[]` | Which namespaces to look to instrument services in Deployments, DaemonSets and StatefulSets. @section -- Beyla |
| beyla.network | bool | `false` | Enable network observability for Beyla. Required for Asserts. @section -- Beyla |
| beyla.process | bool | `false` | Enable process performance signals from instrumented services. @section -- Beyla |
| beyla.traces | bool | `false` | Export OTEL traces. @section -- Beyla |
| cluster.kubernetesAPIService | string | `"kubernetes.default.svc.cluster.local:443"` | The Kubernetes service. Change this if your cluster DNS is configured differently than the default. @section -- Cluster Settings |
| cluster.name | string | `""` | The name of this cluster, which will be set in all labels. Required. @section -- Cluster Settings |
| cluster.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". @section -- Cluster Settings |
| configAnalysis.enabled | bool | `true` | Should `helm test` run the config analysis pod? @section -- Config Analysis Job |
| configAnalysis.extraAnnotations | object | `{}` | Extra annotations to add to the config analysis pod. @section -- Config Analysis Job |
| configAnalysis.extraLabels | object | `{}` | Extra labels to add to the config analysis pod. @section -- Config Analysis Job |
| configAnalysis.image.image | string | `"grafana/k8s-monitoring-test"` | Config Analysis image repository. @section -- Config Analysis Job |
| configAnalysis.image.pullSecrets | list | `[]` | Optional set of image pull secrets. @section -- Config Analysis Job |
| configAnalysis.image.registry | string | `"ghcr.io"` | Config Analysis image registry. @section -- Config Analysis Job |
| configAnalysis.image.tag | string | `""` | Config Analysis image tag. Default is the chart version. @section -- Config Analysis Job |
| configAnalysis.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | nodeSelector to apply to the config analysis pod. @section -- Config Analysis Job |
| configAnalysis.serviceAccount | object | `{"name":""}` | Service Account to use for the config analysis pod. @section -- Config Analysis Job |
| configAnalysis.tolerations | list | `[]` | Tolerations to apply to the config analysis pod. @section -- Config Analysis Job |
| configValidator.enabled | bool | `true` | Should config validation be run? @section -- Config Validator Job |
| configValidator.extraAnnotations | object | `{}` | Extra annotations to add to the test config validator job. @section -- Config Validator Job |
| configValidator.extraLabels | object | `{}` | Extra labels to add to the test config validator job. @section -- Config Validator Job |
| configValidator.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | nodeSelector to apply to the config validator job. @section -- Config Validator Job |
| configValidator.serviceAccount | object | `{"name":""}` | Service Account to use for the config validator job. @section -- Config Validator Job |
| configValidator.tolerations | list | `[]` | Tolerations to apply to the config validator job. @section -- Config Validator Job |
| externalServices.loki.authMode | string | `"basic"` | one of "none", "basic", "oauth2" @section -- External Services (Loki) |
| externalServices.loki.basicAuth.password | string | `""` | Loki basic auth password @section -- External Services (Loki) |
| externalServices.loki.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret @section -- External Services (Loki) |
| externalServices.loki.basicAuth.username | string | `""` | Loki basic auth username @section -- External Services (Loki) |
| externalServices.loki.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret @section -- External Services (Loki) |
| externalServices.loki.externalLabels | object | `{}` | Custom labels to be added to all logs and events, all values are treated as strings and automatically quoted. @section -- External Services (Loki) |
| externalServices.loki.externalLabelsFrom | object | `{}` | Custom labels to be added to all logs and events through a dynamic reference, all values are treated as raw strings and not quoted. @section -- External Services (Loki) |
| externalServices.loki.host | string | `""` | Loki host where logs and events will be sent @section -- External Services (Loki) |
| externalServices.loki.hostKey | string | `"host"` | The key for the host property in the secret @section -- External Services (Loki) |
| externalServices.loki.oauth2.clientId | string | `""` | Loki OAuth2 client ID @section -- External Services (Loki) |
| externalServices.loki.oauth2.clientIdKey | string | `"id"` | The key for the client ID property in the secret @section -- External Services (Loki) |
| externalServices.loki.oauth2.clientSecret | string | `""` | Loki OAuth2 client secret @section -- External Services (Loki) |
| externalServices.loki.oauth2.clientSecretFile | string | `""` | File containing the OAuth2 client secret. @section -- External Services (Loki) |
| externalServices.loki.oauth2.clientSecretKey | string | `"secret"` | The key for the client secret property in the secret @section -- External Services (Loki) |
| externalServices.loki.oauth2.endpointParams | object | `{}` | Loki OAuth2 endpoint parameters @section -- External Services (Loki) |
| externalServices.loki.oauth2.noProxy | string | `""` | Comma-separated list of IP addresses, CIDR notations, and domain names to exclude from proxying. @section -- External Services (Loki) |
| externalServices.loki.oauth2.proxyConnectHeader | object | `{}` | Specifies headers to send to proxies during CONNECT requests. @section -- External Services (Loki) |
| externalServices.loki.oauth2.proxyFromEnvironment | bool | `false` | Use the proxy URL indicated by environment variables. @section -- External Services (Loki) |
| externalServices.loki.oauth2.proxyURL | string | `""` | HTTP proxy to send requests through. @section -- External Services (Loki) |
| externalServices.loki.oauth2.scopes | list | `[]` | List of scopes to authenticate with. @section -- External Services (Loki) |
| externalServices.loki.oauth2.tokenURL | string | `""` | URL to fetch the token from. @section -- External Services (Loki) |
| externalServices.loki.processors.batch.maxSize | int | `0` | Upper limit of a batch size. When set to 0, there is no upper limit. @section -- External Services (Loki) |
| externalServices.loki.processors.batch.size | int | `8192` | Amount of data to buffer before flushing the batch. @section -- External Services (Loki) |
| externalServices.loki.processors.batch.timeout | string | `"2s"` | How long to wait before flushing the batch. @section -- External Services (Loki) |
| externalServices.loki.processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. @section -- External Services (Loki) |
| externalServices.loki.processors.memoryLimiter.enabled | bool | `false` | Use a memory limiter. @section -- External Services (Loki) |
| externalServices.loki.processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. @section -- External Services (Loki) |
| externalServices.loki.protocol | string | `"loki"` | The type of server protocol for writing metrics. Valid options:  `loki` will use Loki's HTTP API,  `otlp` will use OTLP,  `otlphttp` will use OTLP HTTP @section -- External Services (Loki) |
| externalServices.loki.proxyURL | string | `""` | HTTP proxy to proxy requests to Loki through. @section -- External Services (Loki) |
| externalServices.loki.queryEndpoint | string | `"/loki/api/v1/query"` | Loki logs query endpoint. @section -- External Services (Loki) |
| externalServices.loki.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. @section -- External Services (Loki) |
| externalServices.loki.secret.name | string | `""` | The name of the secret. @section -- External Services (Loki) |
| externalServices.loki.secret.namespace | string | `""` | The namespace of the secret. @section -- External Services (Loki) |
| externalServices.loki.tenantId | string | `""` | Loki tenant ID @section -- External Services (Loki) |
| externalServices.loki.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret @section -- External Services (Loki) |
| externalServices.loki.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/loki.write/#tls_config-block) to configure for the logs service. @section -- External Services (Loki) |
| externalServices.loki.writeEndpoint | string | `"/loki/api/v1/push"` | Loki logs write endpoint. @section -- External Services (Loki) |
| externalServices.prometheus.authMode | string | `"basic"` | one of "none", "basic", "oauth2" @section -- External Services (Prometheus) |
| externalServices.prometheus.basicAuth.password | string | `""` | Prometheus basic auth password @section -- External Services (Prometheus) |
| externalServices.prometheus.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret @section -- External Services (Prometheus) |
| externalServices.prometheus.basicAuth.username | string | `""` | Prometheus basic auth username @section -- External Services (Prometheus) |
| externalServices.prometheus.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret @section -- External Services (Prometheus) |
| externalServices.prometheus.externalLabels | object | `{}` | Custom labels to be added to all time series, all values are treated as strings and automatically quoted. @section -- External Services (Prometheus) |
| externalServices.prometheus.externalLabelsFrom | object | `{}` | Custom labels to be added to all time series through a dynamic reference, all values are treated as raw strings and not quoted. @section -- External Services (Prometheus) |
| externalServices.prometheus.host | string | `""` | Prometheus host where metrics will be sent @section -- External Services (Prometheus) |
| externalServices.prometheus.hostKey | string | `"host"` | The key for the host property in the secret @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.clientId | string | `""` | Prometheus OAuth2 client ID @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.clientIdKey | string | `"id"` | The key for the client ID property in the secret @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.clientSecret | string | `""` | Prometheus OAuth2 client secret @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.clientSecretFile | string | `""` | File containing the OAuth2 client secret. @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.clientSecretKey | string | `"secret"` | The key for the client secret property in the secret @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.endpointParams | object | `{}` | Prometheus OAuth2 endpoint parameters @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.noProxy | string | `""` | Comma-separated list of IP addresses, CIDR notations, and domain names to exclude from proxying. @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.proxyConnectHeader | object | `{}` | Specifies headers to send to proxies during CONNECT requests. @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.proxyFromEnvironment | bool | `false` | Use the proxy URL indicated by environment variables. @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.proxyURL | string | `""` | HTTP proxy to send requests through. @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.scopes | list | `[]` | List of scopes to authenticate with. @section -- External Services (Prometheus) |
| externalServices.prometheus.oauth2.tokenURL | string | `""` | URL to fetch the token from. @section -- External Services (Prometheus) |
| externalServices.prometheus.processors.batch.maxSize | int | `0` | Upper limit of a batch size. When set to 0, there is no upper limit. @section -- External Services (Prometheus) |
| externalServices.prometheus.processors.batch.size | int | `8192` | Amount of data to buffer before flushing the batch. @section -- External Services (Prometheus) |
| externalServices.prometheus.processors.batch.timeout | string | `"2s"` | How long to wait before flushing the batch. @section -- External Services (Prometheus) |
| externalServices.prometheus.processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. @section -- External Services (Prometheus) |
| externalServices.prometheus.processors.memoryLimiter.enabled | bool | `false` | Use a memory limiter. @section -- External Services (Prometheus) |
| externalServices.prometheus.processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. @section -- External Services (Prometheus) |
| externalServices.prometheus.protocol | string | `"remote_write"` | The type of server protocol for writing metrics. Valid options:  "remote_write" will use Prometheus Remote Write,  "otlp" will use OTLP,  "otlphttp" will use OTLP HTTP @section -- External Services (Prometheus) |
| externalServices.prometheus.proxyURL | string | `""` | HTTP proxy to proxy requests to Prometheus through. @section -- External Services (Prometheus) |
| externalServices.prometheus.queryEndpoint | string | `"/api/prom/api/v1/query"` | Prometheus metrics query endpoint. Preset for Grafana Cloud Metrics instances. @section -- External Services (Prometheus) |
| externalServices.prometheus.queue_config.batch_send_deadline | string | 5s | Maximum time samples will wait in the buffer before sending. @section -- External Services (Prometheus) |
| externalServices.prometheus.queue_config.capacity | int | 10000 | Number of samples to buffer per shard. @section -- External Services (Prometheus) |
| externalServices.prometheus.queue_config.max_backoff | string | 5s | Maximum retry delay. @section -- External Services (Prometheus) |
| externalServices.prometheus.queue_config.max_samples_per_send | int | 2000 | Maximum number of samples per send. @section -- External Services (Prometheus) |
| externalServices.prometheus.queue_config.max_shards | int | 50 | Maximum number of concurrent shards sending samples to the endpoint. @section -- External Services (Prometheus) |
| externalServices.prometheus.queue_config.min_backoff | string | 30ms | Initial retry delay. The backoff time gets doubled for each retry. @section -- External Services (Prometheus) |
| externalServices.prometheus.queue_config.min_shards | int | 1 | Minimum amount of concurrent shards sending samples to the endpoint. @section -- External Services (Prometheus) |
| externalServices.prometheus.queue_config.retry_on_http_429 | bool | true | Retry when an HTTP 429 status code is received. @section -- External Services (Prometheus) |
| externalServices.prometheus.queue_config.sample_age_limit | string | 0s | Maximum age of samples to send. @section -- External Services (Prometheus) |
| externalServices.prometheus.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. @section -- External Services (Prometheus) |
| externalServices.prometheus.secret.name | string | `""` | The name of the secret. @section -- External Services (Prometheus) |
| externalServices.prometheus.secret.namespace | string | `""` | The namespace of the secret. Only used if secret.create = "false" @section -- External Services (Prometheus) |
| externalServices.prometheus.sendNativeHistograms | bool | `false` | Whether native histograms should be sent. Only applies when protocol is "remote_write". @section -- External Services (Prometheus) |
| externalServices.prometheus.tenantId | string | `""` | Sets the `X-Scope-OrgID` header when sending metrics @section -- External Services (Prometheus) |
| externalServices.prometheus.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret @section -- External Services (Prometheus) |
| externalServices.prometheus.tls | object | `{}` | TLS settings to configure for the metrics service, compatible with [remoteWrite protocol](https://grafana.com/docs/alloy/latest/reference/components/prometheus.remote_write/#tls_config-block), [otlp](https://grafana.com/docs/alloy/latest/reference/components/otelcol.exporter.otlp/#tls-block), or [otlphttp](https://grafana.com/docs/alloy/latest/reference/components/otelcol.exporter.otlphttp/#tls-block) protocols @section -- External Services (Prometheus) |
| externalServices.prometheus.wal.maxKeepaliveTime | string | `"8h"` | Maximum time to keep data in the WAL before removing it. @section -- External Services (Prometheus) |
| externalServices.prometheus.wal.minKeepaliveTime | string | `"5m"` | Minimum time to keep data in the WAL before it can be removed. @section -- External Services (Prometheus) |
| externalServices.prometheus.wal.truncateFrequency | string | `"2h"` | How frequently to clean up the WAL. @section -- External Services (Prometheus) |
| externalServices.prometheus.writeEndpoint | string | `"/api/prom/push"` | Prometheus metrics write endpoint. Preset for Grafana Cloud Metrics instances. @section -- External Services (Prometheus) |
| externalServices.prometheus.writeRelabelConfigRules | string | `""` | Rule blocks to be added to the [write_relabel_config block](https://grafana.com/docs/alloy/latest/reference/components/prometheus.remote_write/#write_relabel_config-block) of the prometheus.remote_write component. @section -- External Services (Prometheus) |
| externalServices.pyroscope.authMode | string | `"basic"` | one of "none", "basic" @section -- External Services (Pyroscope) |
| externalServices.pyroscope.basicAuth.password | string | `""` | Pyroscope basic auth password @section -- External Services (Pyroscope) |
| externalServices.pyroscope.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret @section -- External Services (Pyroscope) |
| externalServices.pyroscope.basicAuth.username | string | `""` | Pyroscope basic auth username @section -- External Services (Pyroscope) |
| externalServices.pyroscope.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret @section -- External Services (Pyroscope) |
| externalServices.pyroscope.externalLabels | object | `{}` | Custom labels to be added to all profiles, all values are treated as strings and automatically quoted. @section -- External Services (Pyroscope) |
| externalServices.pyroscope.externalLabelsFrom | object | `{}` | Custom labels to be added to all profiles through a dynamic reference, all values are treated as raw strings and not quoted. @section -- External Services (Pyroscope) |
| externalServices.pyroscope.host | string | `""` | Pyroscope host where profiles will be sent @section -- External Services (Pyroscope) |
| externalServices.pyroscope.hostKey | string | `"host"` | The key for the host property in the secret @section -- External Services (Pyroscope) |
| externalServices.pyroscope.proxyURL | string | `""` | HTTP proxy to proxy requests to Pyroscope through. @section -- External Services (Pyroscope) |
| externalServices.pyroscope.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. @section -- External Services (Pyroscope) |
| externalServices.pyroscope.secret.name | string | `""` | The name of the secret. @section -- External Services (Pyroscope) |
| externalServices.pyroscope.secret.namespace | string | `""` | The namespace of the secret. @section -- External Services (Pyroscope) |
| externalServices.pyroscope.tenantId | string | `""` | Pyroscope tenant ID @section -- External Services (Pyroscope) |
| externalServices.pyroscope.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret @section -- External Services (Pyroscope) |
| externalServices.pyroscope.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/pyroscope.write/#tls_config-block) to configure for the profiles service. @section -- External Services (Pyroscope) |
| externalServices.tempo.authMode | string | `"basic"` | one of "none", "basic" @section -- External Services (Tempo) |
| externalServices.tempo.basicAuth.password | string | `""` | Tempo basic auth password @section -- External Services (Tempo) |
| externalServices.tempo.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret @section -- External Services (Tempo) |
| externalServices.tempo.basicAuth.username | string | `""` | Tempo basic auth username @section -- External Services (Tempo) |
| externalServices.tempo.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret @section -- External Services (Tempo) |
| externalServices.tempo.host | string | `""` | Tempo host where traces will be sent @section -- External Services (Tempo) |
| externalServices.tempo.hostKey | string | `"host"` | The key for the host property in the secret @section -- External Services (Tempo) |
| externalServices.tempo.protocol | string | `"otlp"` | The type of server protocol for writing metrics Options:   * "otlp" will use OTLP   * "otlphttp" will use OTLP HTTP @section -- External Services (Tempo) |
| externalServices.tempo.searchEndpoint | string | `"/api/search"` | Tempo search endpoint. @section -- External Services (Tempo) |
| externalServices.tempo.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. @section -- External Services (Tempo) |
| externalServices.tempo.secret.name | string | `""` | The name of the secret. @section -- External Services (Tempo) |
| externalServices.tempo.secret.namespace | string | `""` | The namespace of the secret. @section -- External Services (Tempo) |
| externalServices.tempo.tenantId | string | `""` | Tempo tenant ID @section -- External Services (Tempo) |
| externalServices.tempo.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret @section -- External Services (Tempo) |
| externalServices.tempo.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.exporter.otlp/#tls-block) to configure for the traces service. @section -- External Services (Tempo) |
| externalServices.tempo.tlsOptions | string | `""` | Define the [TLS block](https://grafana.com/docs/alloy/latest/reference/components/otelcol.exporter.otlp/#tls-block). Example: `tlsOptions: insecure = true` This option will be deprecated and removed soon. Please switch to `tls` and use yaml format. @section -- External Services (Tempo) |
| extraConfig | string | `""` | Extra configuration that will be added to the Grafana Alloy configuration file. This value is templated so that you can refer to other values from this file. This cannot be used to modify the generated configuration values, only append new components. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example. @section -- Metrics Global |
| extraObjects | list | `[]` | Deploy additional manifest objects |
| global.image.pullSecrets | list | `[]` | Optional set of global image pull secrets. @section -- Image Registry |
| global.image.registry | string | `""` | Global image registry to use if it needs to be overridden for some specific use cases (e.g local registries, custom images, ...) @section -- Image Registry |
| kepler.enabled | bool | `false` | Should this Helm chart deploy Kepler to the cluster. Set this to false if your cluster already has Kepler, or if you do not want to scrape metrics from Kepler. @section -- Deployment: Kepler |
| kube-state-metrics.enabled | bool | `true` | Should this helm chart deploy Kube State Metrics to the cluster. Set this to false if your cluster already has Kube State Metrics, or if you do not want to scrape metrics from Kube State Metrics. @section -- Deployment: [Kube State Metrics](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) |
| kube-state-metrics.metricLabelsAllowlist | list | `["nodes=[*]"]` | `kube_<resource>_labels` metrics to generate. @section -- Deployment: [Kube State Metrics](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) |
| logs.cluster_events.enabled | bool | `true` | Scrape Kubernetes cluster events @section -- Logs Scrape: Cluster Events |
| logs.cluster_events.extraConfig | string | `""` | Extra configuration that will be added to the Grafana Alloy for Cluster Events configuration file. This value is templated so that you can refer to other values from this file. This cannot be used to modify the generated configuration values, only append new components. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example. @section -- Logs Scrape: Cluster Events |
| logs.cluster_events.extraStageBlocks | string | `""` | Stage blocks to be added to the loki.process component for cluster events. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. @section -- Logs Scrape: Cluster Events |
| logs.cluster_events.logFormat | string | `"logfmt"` | Log format used to forward cluster events. Allowed values: `logfmt` (default), `json`. @section -- Logs Scrape: Cluster Events |
| logs.cluster_events.logToStdout | bool | `false` | Logs the cluster events to stdout. Useful for debugging. @section -- Logs Scrape: Cluster Events |
| logs.cluster_events.namespaces | list | `[]` | List of namespaces to watch for events (`[]` means all namespaces) @section -- Logs Scrape: Cluster Events |
| logs.enabled | bool | `true` | Capture and forward logs @section -- Logs Global |
| logs.extraConfig | string | `""` | Extra configuration that will be added to the Grafana Alloy for Logs configuration file. This value is templated so that you can refer to other values from this file. This cannot be used to modify the generated configuration values, only append new components. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example. @section -- Logs Global |
| logs.journal.enabled | bool | `false` | Scrape Kubernetes Worker Journal Logs event @section -- Logs Scrape: Journal |
| logs.journal.extraRelabelingRules | string | `""` | Rule blocks to be added used with the loki.source.journal component for journal logs. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) **Note:** Many field names from journald start with an `_`, such as `_systemd_unit`. The final internal label name would be `__journal__systemd_unit`, with two underscores between `__journal` and `systemd_unit`. @section -- Logs Scrape: Pod Logs |
| logs.journal.extraStageBlocks | string | `""` | Stage blocks to be added to the loki.process component for journal logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. @section -- Logs Scrape: Journal |
| logs.journal.formatAsJson | bool | `false` | Whether to forward the original journal entry as JSON. @section -- Logs Scrape: Journal |
| logs.journal.jobLabel | string | `"integrations/kubernetes/journal"` | The value for the job label for journal logs @section -- Logs Scrape: Journal |
| logs.journal.maxAge | string | `"8h"` | The path to the journal logs on the worker node @section -- Logs Scrape: Journal |
| logs.journal.path | string | `"/var/log/journal"` | The path to the journal logs on the worker node @section -- Logs Scrape: Journal |
| logs.journal.units | list | `[]` | The list of systemd units to keep scraped logs from.  If empty, all units are scraped. @section -- Logs Scrape: Journal |
| logs.podLogsObjects.enabled | bool | `false` | Enable discovery of Grafana Alloy PodLogs objects. @section -- Logs Scrape: PodLog Objects |
| logs.podLogsObjects.extraStageBlocks | string | `""` | Stage blocks to be added to the loki.process component for logs gathered via PodLogs objects. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. @section -- Logs Scrape: PodLog Objects |
| logs.podLogsObjects.namespaces | list | `[]` | Which namespaces to look for PodLogs objects. @section -- Logs Scrape: PodLog Objects |
| logs.podLogsObjects.selector | string | `""` | Selector to filter which PodLogs objects to use. @section -- Logs Scrape: PodLog Objects |
| logs.pod_logs.annotation | string | `"k8s.grafana.com/logs.autogather"` | Pod annotation to use for controlling log discovery. @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.annotations | object | `{"job":"k8s.grafana.com/logs.job"}` | Loki labels to set with values copied from the Kubernetes Pod annotations. Format: `<loki_label>: <kubernetes_annotation>`. @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.discovery | string | `"all"` | Controls the behavior of discovering pods for logs. @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.enabled | bool | `true` | Capture and forward logs from Kubernetes pods @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.excludeNamespaces | list | `[]` | Do not capture logs from any pods in these namespaces. @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for pod logs. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.extraStageBlocks | string | `""` | Stage blocks to be added to the loki.process component for pod logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.gatherMethod | string | `"volumes"` | Controls the behavior of gathering pod logs. When set to `volumes`, Grafana Alloy will use HostPath volume mounts on the cluster nodes to access the pod log files directly. When set to `api`, Grafana Alloy will access pod logs via the API server. This method may be preferable if your cluster prevents DaemonSets, HostPath volume mounts, or for other reasons. @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.labels | object | `{"app_kubernetes_io_name":"app.kubernetes.io/name"}` | Loki labels to set with values copied from the Kubernetes Pod labels. Format: `<loki_label>: <kubernetes_label>`. @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.namespaces | list | `[]` | Only capture logs from pods in these namespaces (`[]` means all namespaces). @section -- Logs Scrape: Pod Logs |
| logs.pod_logs.structuredMetadata | object | `{}` | List of labels to turn into structured metadata. If your Loki instance does not support structured metadata, leave this empty. Format: `<structured metadata>: <Loki label>`. @section -- Logs Scrape: Pod Logs |
| logs.receiver.filters | object | `{"log_record":[]}` | Apply a filter to logs received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.filter/)) @section -- Logs Receiver |
| logs.receiver.transforms | object | `{"labels":["cluster","namespace","job","pod"],"log":[],"resource":[]}` | Apply a transformation to logs received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.transform/)) @section -- Logs Receiver |
| logs.receiver.transforms.labels | list | `["cluster","namespace","job","pod"]` | The list of labels to set in the Loki log stream. @section -- Logs Receiver |
| logs.receiver.transforms.log | list | `[]` | Log transformation rules. @section -- Logs Receiver |
| logs.receiver.transforms.resource | list | `[]` | Resource transformation rules. @section -- Logs Receiver |
| metrics.alloy.enabled | bool | `true` | Scrape metrics from Grafana Alloy @section -- Metrics Job: Alloy |
| metrics.alloy.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Grafana Alloy. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Alloy |
| metrics.alloy.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Grafana Alloy. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Alloy |
| metrics.alloy.labelMatchers | object | `{"app.kubernetes.io/name":"alloy.*"}` | Label matchers used by Grafana Alloy to select Grafana Alloy pods @section -- Metrics Job: Alloy |
| metrics.alloy.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Alloy |
| metrics.alloy.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Alloy |
| metrics.alloy.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. @section -- Metrics Job: Alloy |
| metrics.alloy.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Grafana Alloy to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) @section -- Metrics Job: Alloy |
| metrics.alloy.metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from Grafana Alloy to the minimal set required for Kubernetes Monitoring as well as the Grafana Alloy integration. @section -- Metrics Job: Alloy |
| metrics.alloy.scrapeInterval | string | 60s | How frequently to scrape metrics from Grafana Alloy. Overrides metrics.scrapeInterval @section -- Metrics Job: Alloy |
| metrics.alloyModules.connections | list | `[]` | List of connection configurations used by modules.  Configures the import.git component ([docs](https://grafana.com/docs/alloy/latest/reference/components/import.git/) <br>-   `alias: ""` the alias of the connection <br>-   `repository: ""` URL of the Git repository containing the module. <br>-   `revision: ""` Branch, tag, or commit to be checked out. <br>-   `pull_frequency: 15m` How often the module should check for updates. <br>-   `default: true` If true, this connection is used as the default when none is specified. <br>-   `basic_auth: {}` Credentials for basic authentication if needed. ([docs](https://grafana.com/docs/alloy/latest/reference/config-blocks/import.git/#basic_auth-block)) <br>-   `ssh_key: {}` Provides SSH key details for secure connections. ([docs](https://grafana.com/docs/alloy/latest/reference/config-blocks/import.git/#ssh_key-block)) @section -- Metrics Job: Alloy Modules |
| metrics.alloyModules.modules | list | `[]` | List of Modules to import.  Each module is expected to have a "kubernetes" module and a "scrape" component. Each module can have the following properties: <br>-   `name: ""` the name to use for the module. *note:* this is automatically prefixed with module_ to avoid conflicts with core components <br>-   `path: ""` the path to the alloy module <br>-   `connection: ""` (optional) the alias of the connection to use, if not specified the default connection is used <br>-   `targets: {}` (optional) Additional arguments to be passed to the modules kubernetes component <br>-   `scrape: {}` (optional) Additional arguments to be passed to the modules scrape component <br>-   `extraRelabelingRules: ""` additional relabeling rules for the discovery.relabel component <br>-   `extraMetricRelabelingRules:` additional relabeling rules for the prometheus.relabel component @section -- Metrics Job: Alloy Modules |
| metrics.apiserver.enabled | bool | `false` | Scrape metrics from the API Server @section -- Metrics Job: ApiServer |
| metrics.apiserver.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the API Server. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: ApiServer |
| metrics.apiserver.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the API Server. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: ApiServer |
| metrics.apiserver.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: ApiServer |
| metrics.apiserver.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: ApiServer |
| metrics.apiserver.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. @section -- Metrics Job: ApiServer |
| metrics.apiserver.scrapeInterval | string | 60s | How frequently to scrape metrics from the API Server Overrides metrics.scrapeInterval @section -- Metrics Job: ApiServer |
| metrics.autoDiscover.annotations.instance | string | `"k8s.grafana.com/instance"` | Annotation for overriding the instance label @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.annotations.job | string | `"k8s.grafana.com/job"` | Annotation for overriding the job label @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.annotations.metricsPath | string | `"k8s.grafana.com/metrics.path"` | Annotation for setting or overriding the metrics path. If not set, it defaults to /metrics @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.annotations.metricsPortName | string | `"k8s.grafana.com/metrics.portName"` | Annotation for setting the metrics port by name. @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.annotations.metricsPortNumber | string | `"k8s.grafana.com/metrics.portNumber"` | Annotation for setting the metrics port by number. @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.annotations.metricsScheme | string | `"k8s.grafana.com/metrics.scheme"` | Annotation for setting the metrics scheme, default: http. @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.annotations.metricsScrapeInterval | string | `"k8s.grafana.com/metrics.scrapeInterval"` | Annotation for overriding the scrape interval for this service or pod. Value should be a duration like "15s, 1m". Overrides metrics.autoDiscover.scrapeInterval @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.annotations.scrape | string | `"k8s.grafana.com/scrape"` | Annotation for enabling scraping for this service or pod. Value should be either "true" or "false" @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.enabled | bool | `true` | Enable annotation-based auto-discovery @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for auto-discovered entities. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for auto-discovered entities. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. @section -- Metrics Job: Auto-Discovery |
| metrics.autoDiscover.scrapeInterval | string | 60s | How frequently to scrape metrics from auto-discovered entities. Overrides metrics.scrapeInterval @section -- Metrics Job: Auto-Discovery |
| metrics.cadvisor.enabled | bool | `true` | Scrape container metrics from cAdvisor @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for cAdvisor. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. # ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for cAdvisor. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: cAdvisor |
| metrics.cadvisor.metricsTuning.dropEmptyContainerLabels | bool | `true` | Drop metrics that have an empty container label @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.metricsTuning.dropEmptyImageLabels | bool | `true` | Drop metrics that have an empty image label @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.metricsTuning.keepPhysicalFilesystemDevices | list | `["mmcblk.p.+","nvme.+","rbd.+","sd.+","vd.+","xvd.+","dasd.+"]` | Only keep filesystem metrics that use the following physical devices @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.metricsTuning.keepPhysicalNetworkDevices | list | `["en[ospx][0-9].*","wlan[0-9].*","eth[0-9].*"]` | Only keep network metrics that use the following physical devices @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.metricsTuning.normalizeUnnecessaryLabels | list | `[{"labels":["boot_id","system_uuid"],"metric":"machine_memory_bytes"}]` | Normalize labels to the same value for the given metric and label pairs @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from cAdvisor to the minimal set required for Kubernetes Monitoring. @section -- Metrics Job: cAdvisor See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metrics.cadvisor.nodeAddressFormat | string | `"direct"` | How to access the node services, either direct (use node IP, requires nodes/metrics) or via proxy (requires nodes/proxy) @section -- Metrics Job: cAdvisor |
| metrics.cadvisor.scrapeInterval | string | 60s | How frequently to scrape metrics from cAdvisor. Overrides metrics.scrapeInterval @section -- Metrics Job: cAdvisor |
| metrics.cost.enabled | bool | `true` | Scrape cost metrics from OpenCost @section -- Metrics Job: OpenCost |
| metrics.cost.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for OpenCost. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: OpenCost |
| metrics.cost.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for OpenCost. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: OpenCost |
| metrics.cost.labelMatchers | object | `{"app.kubernetes.io/name":"opencost"}` | Label matchers used to select the OpenCost service @section -- Metrics Job: OpenCost |
| metrics.cost.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: OpenCost |
| metrics.cost.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: OpenCost |
| metrics.cost.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. @section -- Metrics Job: OpenCost |
| metrics.cost.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from OpenCost to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) @section -- Metrics Job: OpenCost |
| metrics.cost.scrapeInterval | string | 60s | How frequently to scrape metrics from OpenCost. Overrides metrics.scrapeInterval @section -- Metrics Job: OpenCost |
| metrics.enabled | bool | `true` | Capture and forward metrics @section -- Metrics Global Settings |
| metrics.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for all metric sources. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Global Settings |
| metrics.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for all metric sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Global Settings |
| metrics.kepler.enabled | bool | `false` | Scrape energy metrics from Kepler @section -- Metrics Job: Kepler |
| metrics.kepler.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kepler. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no __meta* labels are present. @section -- Metrics Job: Kepler |
| metrics.kepler.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kepler. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Kepler |
| metrics.kepler.labelMatchers | object | `{"app.kubernetes.io/name":"kepler"}` | Label matchers used to select the Kepler pods @section -- Metrics Job: Kepler |
| metrics.kepler.maxCacheSize | string | 100000 | Sets the max_cache_size for the prometheus.relabel component for Kepler. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize @section -- Metrics Job: Kepler |
| metrics.kepler.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Kepler |
| metrics.kepler.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. @section -- Metrics Job: Kepler |
| metrics.kepler.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kepler to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) @section -- Metrics Job: Kepler |
| metrics.kepler.scrapeInterval | string | 60s | How frequently to scrape metrics from Kepler. Overrides metrics.scrapeInterval @section -- Metrics Job: Kepler |
| metrics.kube-state-metrics.enabled | bool | `true` | Scrape cluster object metrics from Kube State Metrics @section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kube State Metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kube State Metrics. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.labelMatchers | object | `{"app.kubernetes.io/name":"kube-state-metrics"}` | Label matchers used by Grafana Alloy to select the Kube State Metrics service @section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. @section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kube State Metrics to a useful, minimal set. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) @section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.scrapeInterval | string | 60s | How frequently to scrape metrics from Kube State Metrics. Overrides metrics.scrapeInterval @section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.service.isTLS | bool | `false` | Does this port use TLS? @section -- Metrics Job: Kube State Metrics |
| metrics.kube-state-metrics.service.port | string | `"http"` | Name of the metrics port @section -- Metrics Job: Kube State Metrics |
| metrics.kubeControllerManager.enabled | bool | `false` | Scrape metrics from the Kube Controller Manager @section -- Metrics Job: Kube Controller Manager |
| metrics.kubeControllerManager.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Controller Manager. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Kube Controller Manager |
| metrics.kubeControllerManager.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Controller Manager. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Kube Controller Manager |
| metrics.kubeControllerManager.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Kube Controller Manager |
| metrics.kubeControllerManager.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Kube Controller Manager |
| metrics.kubeControllerManager.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. @section -- Metrics Job: Kube Controller Manager |
| metrics.kubeControllerManager.port | int | `10257` | Port number used by the Kube Controller Manager, set by `--secure-port.` @section -- Metrics Job: Kube Controller Manager |
| metrics.kubeControllerManager.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Controller Manager @section -- Metrics Job: Kube Controller Manager Overrides metrics.scrapeInterval |
| metrics.kubeProxy.enabled | bool | `false` | Scrape metrics from the Kube Proxy @section -- Metrics Job: Kube Proxy |
| metrics.kubeProxy.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Proxy. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Kube Proxy |
| metrics.kubeProxy.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Proxy. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Kube Proxy |
| metrics.kubeProxy.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Kube Proxy |
| metrics.kubeProxy.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Kube Proxy |
| metrics.kubeProxy.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. @section -- Metrics Job: Kube Proxy |
| metrics.kubeProxy.port | int | `10249` | Port number used by the Kube Proxy, set in `--metrics-bind-address`. @section -- Metrics Job: Kube Proxy |
| metrics.kubeProxy.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Proxy Overrides metrics.scrapeInterval @section -- Metrics Job: Kube Proxy |
| metrics.kubeScheduler.enabled | bool | `false` | Scrape metrics from the Kube Scheduler @section -- Metrics Job: Kube Scheduler |
| metrics.kubeScheduler.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Scheduler. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Kube Scheduler |
| metrics.kubeScheduler.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Scheduler. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Kube Scheduler |
| metrics.kubeScheduler.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Kube Scheduler |
| metrics.kubeScheduler.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Kube Scheduler |
| metrics.kubeScheduler.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. @section -- Metrics Job: Kube Scheduler |
| metrics.kubeScheduler.port | int | `10259` | Port number used by the Kube Scheduler, set by `--secure-port`. @section -- Metrics Job: Kube Scheduler |
| metrics.kubeScheduler.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Scheduler Overrides metrics.scrapeInterval @section -- Metrics Job: Kube Scheduler |
| metrics.kubelet.enabled | bool | `true` | Scrape cluster metrics from the Kubelet @section -- Metrics Job: Kubelet |
| metrics.kubelet.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kubelet. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Kubelet |
| metrics.kubelet.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kubelet. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Kubelet |
| metrics.kubelet.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Kubelet |
| metrics.kubelet.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Kubelet |
| metrics.kubelet.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. @section -- Metrics Job: Kubelet |
| metrics.kubelet.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from the Kubelet to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) @section -- Metrics Job: Kubelet |
| metrics.kubelet.nodeAddressFormat | string | `"direct"` | How to access the node services, either direct (use node IP, requires nodes/metrics) or via proxy (requires nodes/proxy) @section -- Metrics Job: Kubelet |
| metrics.kubelet.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kubelet. Overrides metrics.scrapeInterval @section -- Metrics Job: Kubelet |
| metrics.kubernetesMonitoring.enabled | bool | `true` | Report telemetry about this Kubernetes Monitoring chart as a metric. @section -- Metrics Job: Kubernetes Monitoring Telemetry |
| metrics.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. @section -- Metrics Global Settings |
| metrics.node-exporter.enabled | bool | `true` | Scrape node metrics @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Node Exporter. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Node Exporter. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"prometheus-node-exporter.*"}` | Label matchers used to select the Node exporter pods @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Node Exporter |
| metrics.node-exporter.metricsTuning.dropMetricsForFilesystem | list | `["tempfs"]` | Drop metrics for the given filesystem types @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring as well as the Node Exporter integration. @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.scrapeInterval | string | 60s | How frequently to scrape metrics from Node Exporter. Overrides metrics.scrapeInterval @section -- Metrics Job: Node Exporter |
| metrics.node-exporter.service.isTLS | bool | `false` | Does this port use TLS? @section -- Metrics Job: Node Exporter |
| metrics.podMonitors.enabled | bool | `true` | Enable discovery of Prometheus Operator PodMonitor objects. @section -- Metrics Job: Prometheus Operator (PodMonitors) |
| metrics.podMonitors.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for PodMonitor objects. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Prometheus Operator (PodMonitors) |
| metrics.podMonitors.extraRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.operator.podmonitors component for PodMonitors. These relabeling rules are applied pre-scrape against the targets from service discovery. The relabelings defined in the PodMonitor object are applied first, then these relabelings are applied. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Prometheus Operator (PodMonitors) |
| metrics.podMonitors.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Prometheus Operator (PodMonitors) |
| metrics.podMonitors.namespaces | list | `[]` | Which namespaces to look for PodMonitor objects. @section -- Metrics Job: Prometheus Operator (PodMonitors) |
| metrics.podMonitors.scrapeInterval | string | 60s | How frequently to scrape metrics from PodMonitor objects. Only used if the PodMonitor does not specify the scrape interval. Overrides metrics.scrapeInterval @section -- Metrics Job: Prometheus Operator (PodMonitors) |
| metrics.podMonitors.selector | string | `""` | Selector to filter which PodMonitor objects to use. @section -- Metrics Job: Prometheus Operator (PodMonitors) |
| metrics.probes.enabled | bool | `true` | Enable discovery of Prometheus Operator Probe objects. @section -- Metrics Job: Prometheus Operator (Probes) |
| metrics.probes.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Probe objects. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Prometheus Operator (Probes) |
| metrics.probes.extraRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.operator.probes component for Probes. These relabeling rules are applied pre-scrape against the targets from service discovery. The relabelings defined in the PodMonitor object are applied first, then these relabelings are applied. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Prometheus Operator (Probes) |
| metrics.probes.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Prometheus Operator (Probes) |
| metrics.probes.namespaces | list | `[]` | Which namespaces to look for Probe objects. @section -- Metrics Job: Prometheus Operator (Probes) |
| metrics.probes.scrapeInterval | string | 60s | How frequently to scrape metrics from Probe objects. Only used if the Probe does not specify the scrape interval. Overrides metrics.scrapeInterval @section -- Metrics Job: Prometheus Operator (Probes) |
| metrics.probes.selector | string | `""` | Selector to filter which Probes objects to use. @section -- Metrics Job: Prometheus Operator (Probes) |
| metrics.receiver.filters | object | `{"datapoint":[],"metric":[]}` | Apply a filter to metrics received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.filter/)) @section -- Metrics Receivers |
| metrics.receiver.transforms | object | `{"datapoint":[],"metric":[],"resource":[]}` | Apply a transformation to metrics received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.transform/)) @section -- Metrics Receivers |
| metrics.scrapeInterval | string | `"60s"` | How frequently to scrape metrics @section -- Metrics Global Settings |
| metrics.serviceMonitors.enabled | bool | `true` | Enable discovery of Prometheus Operator ServiceMonitor objects. @section -- Metrics Job: Prometheus Operator (ServiceMonitors) |
| metrics.serviceMonitors.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for ServiceMonitor objects. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Prometheus Operator (ServiceMonitors) |
| metrics.serviceMonitors.extraRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.operator.probes component for Probes. These relabeling rules are applied pre-scrape against the targets from service discovery. The relabelings defined in the PodMonitor object are applied first, then these relabelings are applied. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Prometheus Operator (ServiceMonitors) |
| metrics.serviceMonitors.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Prometheus Operator (ServiceMonitors) |
| metrics.serviceMonitors.namespaces | list | `[]` | Which namespaces to look for ServiceMonitor objects. @section -- Metrics Job: Prometheus Operator (ServiceMonitors) |
| metrics.serviceMonitors.scrapeInterval | string | 60s | How frequently to scrape metrics from ServiceMonitor objects. Only used if the ServiceMonitor does not specify the scrape interval. Overrides metrics.scrapeInterval @section -- Metrics Job: Prometheus Operator (ServiceMonitors) |
| metrics.serviceMonitors.selector | string | `""` | Selector to filter which ServiceMonitor objects to use. @section -- Metrics Job: Prometheus Operator (ServiceMonitors) |
| metrics.windows-exporter.enabled | bool | `false` | Scrape node metrics @section -- Metrics Job: Windows Exporter |
| metrics.windows-exporter.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Windows Exporter. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) @section -- Metrics Job: Windows Exporter |
| metrics.windows-exporter.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Windows Exporter. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Metrics Job: Windows Exporter |
| metrics.windows-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"prometheus-windows-exporter.*"}` | Label matchers used to select the Windows Exporter pods @section -- Metrics Job: Windows Exporter |
| metrics.windows-exporter.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize
@section -- Metrics Job: Windows Exporter |
| metrics.windows-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. @section -- Metrics Job: Windows Exporter |
| metrics.windows-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. @section -- Metrics Job: Windows Exporter |
| metrics.windows-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Windows Exporter to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) @section -- Metrics Job: Windows Exporter |
| metrics.windows-exporter.scrapeInterval | string | 60s | How frequently to scrape metrics from Windows Exporter. Overrides metrics.scrapeInterval @section -- Metrics Job: Windows Exporter |
| opencost.enabled | bool | `true` | Should this Helm chart deploy OpenCost to the cluster. Set this to false if your cluster already has OpenCost, or if you do not want to scrape metrics from OpenCost. @section -- Deployment: [OpenCost](https://github.com/opencost/opencost-helm-chart) |
| opencost.opencost.prometheus.existingSecretName | string | `"prometheus-k8s-monitoring"` | The name of the secret containing the username and password for the metrics service. This must be in the same namespace as the OpenCost deployment. @section -- Deployment: [OpenCost](https://github.com/opencost/opencost-helm-chart) |
| opencost.opencost.prometheus.external.url | string | `"https://prom.example.com/api/prom"` | The URL for Prometheus queries. It should match externalServices.prometheus.host + "/api/prom" @section -- Deployment: [OpenCost](https://github.com/opencost/opencost-helm-chart)3 |
| opencost.opencost.prometheus.password_key | string | `"password"` | The key for the password property in the secret. @section -- Deployment: [OpenCost](https://github.com/opencost/opencost-helm-chart) |
| opencost.opencost.prometheus.username_key | string | `"username"` | The key for the username property in the secret. @section -- Deployment: [OpenCost](https://github.com/opencost/opencost-helm-chart) |
| profiles.ebpf.demangle | string | `"none"` | C++ demangle mode. Available options are: none, simplified, templates, full @section -- Profiles (eBPF) |
| profiles.ebpf.enabled | bool | `true` | Gather profiles using eBPF @section -- Profiles (eBPF) |
| profiles.ebpf.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Profiles (eBPF) |
| profiles.ebpf.namespaces | list | `[]` | Which namespaces to look for pods with profiles. @section -- Profiles (eBPF) |
| profiles.enabled | bool | `false` | Receive and forward profiles. @section -- Profiles |
| profiles.java.enabled | bool | `true` | Gather profiles by scraping java HTTP endpoints @section -- Profiles (java) |
| profiles.java.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Java profile sources. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Profiles (java) |
| profiles.java.namespaces | list | `[]` | Which namespaces to look for pods with profiles. @section -- Profiles (java) |
| profiles.java.profilingConfig | object | `{"alloc":"512k","cpu":true,"interval":"60s","lock":"10ms","sampleRate":100}` | Configuration for the async-profiler @section -- Profiles (java) |
| profiles.pprof.enabled | bool | `true` | Gather profiles by scraping pprof HTTP endpoints @section -- Profiles (pprof) |
| profiles.pprof.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) @section -- Profiles (pprof) |
| profiles.pprof.namespaces | list | `[]` | Which namespaces to look for pods with profiles. @section -- Profiles (pprof) |
| profiles.pprof.types | list | `["memory","cpu","goroutine","block","mutex","fgprof"]` | Profile types to gather @section -- Profiles (pprof) |
| prometheus-node-exporter.enabled | bool | `true` | Should this helm chart deploy Node Exporter to the cluster. Set this to false if your cluster already has Node Exporter, or if you do not want to scrape metrics from Node Exporter. @section -- Deployment: [Prometheus Node Exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter) |
| prometheus-operator-crds.enabled | bool | `true` | Should this helm chart deploy the Prometheus Operator CRDs to the cluster. Set this to false if your cluster already has the CRDs, or if you do not to have Grafana Alloy scrape metrics from PodMonitors, Probes, or ServiceMonitors. @section -- Deployment: [Prometheus Operator CRDs](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-operator-crds) |
| prometheus-windows-exporter.enabled | bool | `false` | Should this helm chart deploy Windows Exporter to the cluster. Set this to false if your cluster already has Windows Exporter, or if you do not want to scrape metrics from Windows Exporter. @section -- Deployment: [Prometheus Windows Exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-windows-exporter) |
| receivers.deployGrafanaAgentService | bool | `true` | Deploy a service named for Grafana Agent that matches the Alloy service. This is useful for applications that are configured to send telemetry to a service named "grafana-agent" and not yet updated to send to "alloy". @section -- OTEL Receivers |
| receivers.grafanaCloudMetrics.enabled | bool | `true` | Generate host info metrics from telemetry data, used in Application Observability in Grafana Cloud. @section -- OTEL Receivers (Processors) |
| receivers.grpc.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. @section -- OTEL Receivers (gRPC) |
| receivers.grpc.enabled | bool | `true` | Receive OpenTelemetry signals over OTLP/gRPC? @section -- OTEL Receivers (gRPC) |
| receivers.grpc.port | int | `4317` | Which port to use for the OTLP/gRPC receiver. This port needs to be opened in the alloy section below. @section -- OTEL Receivers (gRPC) |
| receivers.grpc.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.receiver.otlp/#tls-block) to configure for the OTLP/gRPC receiver. @section -- OTEL Receivers (gRPC) |
| receivers.http.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. @section -- OTEL Receivers (HTTP) |
| receivers.http.enabled | bool | `true` | Receive OpenTelemetry signals over OTLP/HTTP? @section -- OTEL Receivers (HTTP) |
| receivers.http.port | int | `4318` | Which port to use for the OTLP/HTTP receiver. This port needs to be opened in the alloy section below. @section -- OTEL Receivers (HTTP) |
| receivers.http.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.receiver.otlp/#tls-block) to configure for the OTLP/HTTP receiver. @section -- OTEL Receivers (HTTP) |
| receivers.jaeger.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. @section -- OTEL Receivers (Jaeger) |
| receivers.jaeger.grpc.enabled | bool | `false` | Receive Jaeger signals via gRPC protocol. @section -- OTEL Receivers (Jaeger) |
| receivers.jaeger.grpc.port | int | `14250` | Which port to use for the Jaeger gRPC receiver. This port needs to be opened in the alloy section below. @section -- OTEL Receivers (Jaeger) |
| receivers.jaeger.thriftBinary.enabled | bool | `false` | Receive Jaeger signals via Thrift binary protocol. @section -- OTEL Receivers (Jaeger) |
| receivers.jaeger.thriftBinary.port | int | `6832` | Which port to use for the Thrift binary receiver. This port needs to be opened in the alloy section below. @section -- OTEL Receivers (Jaeger) |
| receivers.jaeger.thriftCompact.enabled | bool | `false` | Receive Jaeger signals via Thrift compact protocol. @section -- OTEL Receivers (Jaeger) |
| receivers.jaeger.thriftCompact.port | int | `6831` | Which port to use for the Thrift compact receiver. This port needs to be opened in the alloy section below. @section -- OTEL Receivers (Jaeger) |
| receivers.jaeger.thriftHttp.enabled | bool | `false` | Receive Jaeger signals via Thrift HTTP protocol. @section -- OTEL Receivers (Jaeger) |
| receivers.jaeger.thriftHttp.port | int | `14268` | Which port to use for the Thrift HTTP receiver. This port needs to be opened in the alloy section below. @section -- OTEL Receivers (Jaeger) |
| receivers.jaeger.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.receiver.jaeger/#tls-block) to configure for the Jaeger receiver. @section -- OTEL Receivers (Jaeger) |
| receivers.processors.batch.maxSize | int | `0` | The upper limit of the amount of data contained in a single batch, in bytes. When set to 0, batches can be any size. @section -- OTEL Receivers (Processors) |
| receivers.processors.batch.size | int | `16384` | What batch size to use, in bytes @section -- OTEL Receivers (Processors) |
| receivers.processors.batch.timeout | string | `"2s"` | How long before sending (Processors) @section -- OTEL Receivers (Processors) |
| receivers.processors.k8sattributes.annotations | list | `[]` | Kubernetes annotations to extract and add to the attributes of the received telemetry data. @section -- OTEL Receivers (Processors) |
| receivers.processors.k8sattributes.labels | list | `[]` | Kubernetes labels to extract and add to the attributes of the received telemetry data. @section -- OTEL Receivers (Processors) |
| receivers.processors.k8sattributes.metadata | list | `["k8s.namespace.name","k8s.pod.name","k8s.deployment.name","k8s.statefulset.name","k8s.daemonset.name","k8s.cronjob.name","k8s.job.name","k8s.node.name","k8s.pod.uid","k8s.pod.start_time"]` | Kubernetes metadata to extract and add to the attributes of the received telemetry data. @section -- OTEL Receivers (Processors) |
| receivers.prometheus.enabled | bool | `false` | Receive Prometheus metrics @section -- OTEL Receivers (Prometheus) |
| receivers.prometheus.port | int | `9999` | Which port to use for the Prometheus receiver. This port needs to be opened in the alloy section below. @section -- OTEL Receivers (Prometheus) |
| receivers.zipkin.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. @section -- OTEL Receivers (Zipkin) |
| receivers.zipkin.enabled | bool | `false` | Receive Zipkin traces @section -- OTEL Receivers (Zipkin) |
| receivers.zipkin.port | int | `9411` | Which port to use for the Zipkin receiver. This port needs to be opened in the alloy section below. @section -- OTEL Receivers (Zipkin) |
| receivers.zipkin.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.receiver.zipkin/#tls-block) to configure for the Zipkin receiver. @section -- OTEL Receivers (Zipkin) |
| test.attempts | int | `10` | How many times to attempt the test job. @section -- Test Job |
| test.enabled | bool | `true` | Should `helm test` run the test job? @section -- Test Job |
| test.envOverrides | object | `{"LOKI_URL":"","PROFILECLI_URL":"","PROMETHEUS_URL":"","TEMPO_URL":""}` | Overrides the URLs for various data sources @section -- Test Job |
| test.extraAnnotations | object | `{}` | Extra annotations to add to the test job. @section -- Test Job |
| test.extraLabels | object | `{}` | Extra labels to add to the test job. @section -- Test Job |
| test.extraQueries | list | `[]` | Additional queries to run during the test. See the [Helm tests docs](./docs/HelmTests.md) for more information. @section -- Test Job |
| test.image.image | string | `"grafana/k8s-monitoring-test"` | Test job image repository. @section -- Test Job |
| test.image.pullSecrets | list | `[]` | Optional set of image pull secrets. @section -- Test Job |
| test.image.registry | string | `"ghcr.io"` | Test job image registry. @section -- Test Job |
| test.image.tag | string | `""` | Test job image tag. Default is the chart version. @section -- Test Job |
| test.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | nodeSelector to apply to the test job. @section -- Test Job |
| test.serviceAccount | object | `{"name":""}` | Service Account to use for the test job. @section -- Test Job |
| test.tolerations | list | `[]` | Tolerations to apply to the test job. @section -- Test Job |
| traces.enabled | bool | `false` | Receive and forward traces. @section -- Traces |
| traces.receiver.filters | object | `{"span":[],"spanevent":[]}` | Apply a filter to traces received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.filter/)) @section -- Traces |
| traces.receiver.transforms | object | `{"resource":[],"span":[],"spanevent":[]}` | Apply a transformation to traces received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.transform/)) @section -- Traces |

## Customizing the configuration

There are several options for customizing the configuration generated by this chart. This can be used to add extra
scrape targets, for example, to [scrape metrics from an application](./docs/ScrapeApplicationMetrics.md) deployed on the
same Kubernetes cluster.

### Adding custom Flow configuration

Any value supplied to the `.extraConfig` or `.logs.extraConfig` values will be appended to the generated config file
after being templated with Helm, so that you can refer to any values from this chart. This can be used to add more
Grafana Alloy components to provide extra functionality to the Alloy instance.

NOTE: This cannot be used to modify existing configuration values.

Extra flow components can re-use any of the existing components in the generated configuration, which includes several
useful ones like these:

-   `discovery.kubernetes.nodes` - Discovers all nodes in the cluster
-   `discovery.kubernetes.pods` - Discovers all pods in the cluster
-   `discovery.kubernetes.services` - Discovers all services in the cluster
-   `prometheus.relabel.metrics_service` - Sends metrics to the metrics service defined by `.externalServices.prometheus`
-   `loki.process.logs_service` - Sends logs to the logs service defined by `.externalServices.loki`

Example:

In this example, Alloy will find a service named `my-webapp-metrics` with the label `app.kubernetes.io/name=my-webapp`,
scrape them for Prometheus metrics, and send those metrics to Grafana Cloud.

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

The default config will deploy the CRDs for Prometheus Operator, and will add support for `PodMonitor`,
`ServiceMonitor` and `Probe` objects. Deploying a PodMonitor or a ServiceMonitor will be discovered and utilized by Alloy.

Use a selector to limit the discovered objects.

Example:

In this example, Alloy will find `ServiceMonitor` objects labeled with `example.com/environment=production`, scrape them
for Prometheus metrics, and send those metrics to Grafana Cloud.

```yaml
serviceMonitors:
  enabled: true
  selector: |-
    match_expression {
      key = "example.com/environment"
      operator = "In"
      values = ["production"]
    }

```

## Troubleshooting

If you're encountering issues deploying or using this chart, check the [Troubleshooting doc](./docs/Troubleshooting.md).

## Metrics Tuning and Allow Lists

This chart uses predefined "allow lists" to control the amount of metrics delivered to the metrics service.
[This document](./default_allow_lists) explains the allow lists and shows their contents.
