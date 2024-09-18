<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring

![Version: 1.5.2](https://img.shields.io/badge/Version-1.5.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.8.2](https://img.shields.io/badge/AppVersion-2.8.2-informational?style=flat-square)

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
| https://grafana.github.io/helm-charts | alloy | 0.7.0 |
| https://grafana.github.io/helm-charts | alloy-events(alloy) | 0.7.0 |
| https://grafana.github.io/helm-charts | alloy-logs(alloy) | 0.7.0 |
| https://grafana.github.io/helm-charts | alloy-profiles(alloy) | 0.7.0 |
| https://grafana.github.io/helm-charts | beyla | 1.4.0 |
| https://opencost.github.io/opencost-helm-chart | opencost | 1.42.0 |
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 5.25.1 |
| https://prometheus-community.github.io/helm-charts | prometheus-node-exporter | 4.39.0 |
| https://prometheus-community.github.io/helm-charts | prometheus-operator-crds | 14.0.0 |
| https://prometheus-community.github.io/helm-charts | prometheus-windows-exporter | 0.6.0 |
| https://sustainable-computing-io.github.io/kepler-helm-chart | kepler | 0.5.9 |
<!-- markdownlint-enable no-bare-urls -->

## Values

### Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Cluster Events Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-events.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |
| alloy-events.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| alloy-events.logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Logs Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-logs.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |
| alloy-logs.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| alloy-logs.logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy) for Profiles Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy-profiles.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |
| alloy-profiles.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| alloy-profiles.logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Deployment: [Alloy](https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy.enabled | bool | `true` | Deploy this Alloy instance. Only set this to false if you are not using metrics or any receivers. |
| alloy.liveDebugging.enabled | bool | `false` | Enable live debugging for the Alloy instance. Requires stability level to be set to "experimental". |
| alloy.logging.format | string | `"logfmt"` | Format to use for writing Alloy log lines. |
| alloy.logging.level | string | `"info"` | Level at which Alloy log lines should be written. |

### Deployment: Beyla

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| beyla.config.data | object | `{"attributes":{"kubernetes":{"enable":true}},"internal_metrics":{"prometheus":{"path":"/internal/metrics","port":9090}},"prometheus_export":{"features":["application","network","application_service_graph","application_span"],"path":"/metrics","port":9090}}` | The Configuration for Beyla |
| beyla.enabled | bool | `false` | Should this Helm chart deploy Grafana Beyla to the cluster. |

### Cluster Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cluster.kubernetesAPIService | string | `"kubernetes.default.svc.cluster.local:443"` | The Kubernetes service. Change this if your cluster DNS is configured differently than the default. |
| cluster.name | string | `""` | The name of this cluster, which will be set in all labels. Required. |
| cluster.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |

### Config Analysis Job

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| configAnalysis.enabled | bool | `true` | Should `helm test` run the config analysis pod? |
| configAnalysis.extraAnnotations | object | `{}` | Extra annotations to add to the config analysis pod. |
| configAnalysis.extraLabels | object | `{}` | Extra labels to add to the config analysis pod. |
| configAnalysis.image.image | string | `"grafana/k8s-monitoring-test"` | Config Analysis image repository. |
| configAnalysis.image.pullSecrets | list | `[]` | Optional set of image pull secrets. |
| configAnalysis.image.registry | string | `"ghcr.io"` | Config Analysis image registry. |
| configAnalysis.image.tag | string | `""` | Config Analysis image tag. Default is the chart version. |
| configAnalysis.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | nodeSelector to apply to the config analysis pod. |
| configAnalysis.serviceAccount | object | `{"name":""}` | Service Account to use for the config analysis pod. |
| configAnalysis.tolerations | list | `[]` | Tolerations to apply to the config analysis pod. |

### Config Validator Job

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| configValidator.enabled | bool | `true` | Should config validation be run? |
| configValidator.extraAnnotations | object | `{}` | Extra annotations to add to the test config validator job. |
| configValidator.extraLabels | object | `{}` | Extra labels to add to the test config validator job. |
| configValidator.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | nodeSelector to apply to the config validator job. |
| configValidator.serviceAccount | object | `{"name":""}` | Service Account to use for the config validator job. |
| configValidator.tolerations | list | `[{"effect":"NoSchedule","key":"kubernetes.io/arch","operator":"Equal","value":"arm64"}]` | Tolerations to apply to the config validator job. |

### External Services (Loki)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| externalServices.loki.authMode | string | `"basic"` | one of "none", "basic", "oauth2" |
| externalServices.loki.basicAuth.password | string | `""` | Loki basic auth password |
| externalServices.loki.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret |
| externalServices.loki.basicAuth.username | string | `""` | Loki basic auth username |
| externalServices.loki.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret |
| externalServices.loki.externalLabels | object | `{}` | Custom labels to be added to all logs and events. All values are treated as strings and automatically quoted. |
| externalServices.loki.externalLabelsFrom | object | `{}` | Custom labels to be added to all logs and events through a dynamic reference. All values are treated as raw strings and not quoted. |
| externalServices.loki.extraHeaders | object | `{}` | Extra headers to be set when sending metrics. All values are treated as strings and automatically quoted. |
| externalServices.loki.extraHeadersFrom | object | `{}` | Extra headers to be set when sending metrics through a dynamic reference. All values are treated as raw strings and not quoted. |
| externalServices.loki.host | string | `""` | Loki host where logs and events will be sent |
| externalServices.loki.hostKey | string | `"host"` | The key for the host property in the secret |
| externalServices.loki.oauth2.clientId | string | `""` | Loki OAuth2 client ID |
| externalServices.loki.oauth2.clientIdKey | string | `"id"` | The key for the client ID property in the secret |
| externalServices.loki.oauth2.clientSecret | string | `""` | Loki OAuth2 client secret |
| externalServices.loki.oauth2.clientSecretFile | string | `""` | File containing the OAuth2 client secret. |
| externalServices.loki.oauth2.clientSecretKey | string | `"secret"` | The key for the client secret property in the secret |
| externalServices.loki.oauth2.endpointParams | object | `{}` | Loki OAuth2 endpoint parameters |
| externalServices.loki.oauth2.noProxy | string | `""` | Comma-separated list of IP addresses, CIDR notations, and domain names to exclude from proxying. |
| externalServices.loki.oauth2.proxyConnectHeader | object | `{}` | Specifies headers to send to proxies during CONNECT requests. |
| externalServices.loki.oauth2.proxyFromEnvironment | bool | `false` | Use the proxy URL indicated by environment variables. |
| externalServices.loki.oauth2.proxyURL | string | `""` | HTTP proxy to send requests through. |
| externalServices.loki.oauth2.scopes | list | `[]` | List of scopes to authenticate with. |
| externalServices.loki.oauth2.tokenURL | string | `""` | URL to fetch the token from. |
| externalServices.loki.processors.batch.maxSize | int | `0` | Upper limit of a batch size. When set to 0, there is no upper limit. |
| externalServices.loki.processors.batch.size | int | `8192` | Amount of data to buffer before flushing the batch. |
| externalServices.loki.processors.batch.timeout | string | `"2s"` | How long to wait before flushing the batch. |
| externalServices.loki.processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. |
| externalServices.loki.processors.memoryLimiter.enabled | bool | `false` | Use a memory limiter. |
| externalServices.loki.processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. |
| externalServices.loki.protocol | string | `"loki"` | The type of server protocol for writing metrics. Valid options:  `loki` will use Loki's HTTP API,  `otlp` will use OTLP,  `otlphttp` will use OTLP HTTP |
| externalServices.loki.proxyURL | string | `""` | HTTP proxy to proxy requests to Loki through. |
| externalServices.loki.queryEndpoint | string | `"/loki/api/v1/query"` | Loki logs query endpoint. |
| externalServices.loki.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. |
| externalServices.loki.secret.name | string | `""` | The name of the secret. |
| externalServices.loki.secret.namespace | string | `""` | The namespace of the secret. |
| externalServices.loki.tenantId | string | `""` | Loki tenant ID |
| externalServices.loki.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret |
| externalServices.loki.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/loki.write/#tls_config-block) to configure for the logs service. |
| externalServices.loki.writeEndpoint | string | `"/loki/api/v1/push"` | Loki logs write endpoint. |

### External Services (Prometheus)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| externalServices.prometheus.authMode | string | `"basic"` | one of "none", "basic", "oauth2", "bearerToken" |
| externalServices.prometheus.basicAuth.password | string | `""` | Prometheus basic auth password |
| externalServices.prometheus.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret |
| externalServices.prometheus.basicAuth.username | string | `""` | Prometheus basic auth username |
| externalServices.prometheus.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret |
| externalServices.prometheus.bearerToken.token | string | `""` | Configure the Prometheus Remote Write Bearer Token |
| externalServices.prometheus.bearerToken.tokenFile | string | `""` | Configure the Prometheus Remote Write Bearer Token file |
| externalServices.prometheus.bearerToken.tokenKey | string | `"bearerToken"` | Configure the Key for Prometheus Remote Write Bearer Token secret |
| externalServices.prometheus.externalLabels | object | `{}` | Custom labels to be added to all time series. All values are treated as strings and automatically quoted. |
| externalServices.prometheus.externalLabelsFrom | object | `{}` | Custom labels to be added to all time series through a dynamic reference. All values are treated as raw strings and not quoted. |
| externalServices.prometheus.extraHeaders | object | `{}` | Extra headers to be set when sending metrics. All values are treated as strings and automatically quoted. |
| externalServices.prometheus.extraHeadersFrom | object | `{}` | Extra headers to be set when sending metrics through a dynamic reference. All values are treated as raw strings and not quoted. |
| externalServices.prometheus.host | string | `""` | Prometheus host where metrics will be sent |
| externalServices.prometheus.hostKey | string | `"host"` | The key for the host property in the secret |
| externalServices.prometheus.oauth2.clientId | string | `""` | Prometheus OAuth2 client ID |
| externalServices.prometheus.oauth2.clientIdKey | string | `"id"` | The key for the client ID property in the secret |
| externalServices.prometheus.oauth2.clientSecret | string | `""` | Prometheus OAuth2 client secret |
| externalServices.prometheus.oauth2.clientSecretFile | string | `""` | File containing the OAuth2 client secret. |
| externalServices.prometheus.oauth2.clientSecretKey | string | `"secret"` | The key for the client secret property in the secret |
| externalServices.prometheus.oauth2.endpointParams | object | `{}` | Prometheus OAuth2 endpoint parameters |
| externalServices.prometheus.oauth2.noProxy | string | `""` | Comma-separated list of IP addresses, CIDR notations, and domain names to exclude from proxying. |
| externalServices.prometheus.oauth2.proxyConnectHeader | object | `{}` | Specifies headers to send to proxies during CONNECT requests. |
| externalServices.prometheus.oauth2.proxyFromEnvironment | bool | `false` | Use the proxy URL indicated by environment variables. |
| externalServices.prometheus.oauth2.proxyURL | string | `""` | HTTP proxy to send requests through. |
| externalServices.prometheus.oauth2.scopes | list | `[]` | List of scopes to authenticate with. |
| externalServices.prometheus.oauth2.tokenURL | string | `""` | URL to fetch the token from. |
| externalServices.prometheus.processors.batch.maxSize | int | `0` | Upper limit of a batch size. When set to 0, there is no upper limit. |
| externalServices.prometheus.processors.batch.size | int | `8192` | Amount of data to buffer before flushing the batch. |
| externalServices.prometheus.processors.batch.timeout | string | `"2s"` | How long to wait before flushing the batch. |
| externalServices.prometheus.processors.memoryLimiter.checkInterval | string | `"1s"` | How often to check memory usage. |
| externalServices.prometheus.processors.memoryLimiter.enabled | bool | `false` | Use a memory limiter. |
| externalServices.prometheus.processors.memoryLimiter.limit | string | `"0MiB"` | Maximum amount of memory targeted to be allocated by the process heap. |
| externalServices.prometheus.protocol | string | `"remote_write"` | The type of server protocol for writing metrics. Valid options:  "remote_write" will use Prometheus Remote Write,  "otlp" will use OTLP,  "otlphttp" will use OTLP HTTP |
| externalServices.prometheus.proxyURL | string | `""` | HTTP proxy to proxy requests to Prometheus through. |
| externalServices.prometheus.queryEndpoint | string | `"/api/prom/api/v1/query"` | Prometheus metrics query endpoint. Preset for Grafana Cloud Metrics instances. |
| externalServices.prometheus.queue_config.batch_send_deadline | string | 5s | Maximum time samples will wait in the buffer before sending. |
| externalServices.prometheus.queue_config.capacity | int | 10000 | Number of samples to buffer per shard. |
| externalServices.prometheus.queue_config.max_backoff | string | 5s | Maximum retry delay. |
| externalServices.prometheus.queue_config.max_samples_per_send | int | 2000 | Maximum number of samples per send. |
| externalServices.prometheus.queue_config.max_shards | int | 50 | Maximum number of concurrent shards sending samples to the endpoint. |
| externalServices.prometheus.queue_config.min_backoff | string | 30ms | Initial retry delay. The backoff time gets doubled for each retry. |
| externalServices.prometheus.queue_config.min_shards | int | 1 | Minimum amount of concurrent shards sending samples to the endpoint. |
| externalServices.prometheus.queue_config.retry_on_http_429 | bool | true | Retry when an HTTP 429 status code is received. |
| externalServices.prometheus.queue_config.sample_age_limit | string | 0s | Maximum age of samples to send. |
| externalServices.prometheus.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. |
| externalServices.prometheus.secret.name | string | `""` | The name of the secret. |
| externalServices.prometheus.secret.namespace | string | `""` | The namespace of the secret. Only used if secret.create = "false" |
| externalServices.prometheus.sendNativeHistograms | bool | `false` | Whether native histograms should be sent. Only applies when protocol is "remote_write". |
| externalServices.prometheus.tenantId | string | `""` | Sets the `X-Scope-OrgID` header when sending metrics |
| externalServices.prometheus.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret |
| externalServices.prometheus.tls | object | `{}` | TLS settings to configure for the metrics service, compatible with [remoteWrite protocol](https://grafana.com/docs/alloy/latest/reference/components/prometheus.remote_write/#tls_config-block), [otlp](https://grafana.com/docs/alloy/latest/reference/components/otelcol.exporter.otlp/#tls-block), or [otlphttp](https://grafana.com/docs/alloy/latest/reference/components/otelcol.exporter.otlphttp/#tls-block) protocols |
| externalServices.prometheus.wal.maxKeepaliveTime | string | `"8h"` | Maximum time to keep data in the WAL before removing it. |
| externalServices.prometheus.wal.minKeepaliveTime | string | `"5m"` | Minimum time to keep data in the WAL before it can be removed. |
| externalServices.prometheus.wal.truncateFrequency | string | `"2h"` | How frequently to clean up the WAL. |
| externalServices.prometheus.writeEndpoint | string | `"/api/prom/push"` | Prometheus metrics write endpoint. Preset for Grafana Cloud Metrics instances. |
| externalServices.prometheus.writeRelabelConfigRules | string | `""` | Rule blocks to be added to the [write_relabel_config block](https://grafana.com/docs/alloy/latest/reference/components/prometheus.remote_write/#write_relabel_config-block) of the prometheus.remote_write component. |

### External Services (Pyroscope)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| externalServices.pyroscope.authMode | string | `"basic"` | one of "none", "basic" |
| externalServices.pyroscope.basicAuth.password | string | `""` | Pyroscope basic auth password |
| externalServices.pyroscope.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret |
| externalServices.pyroscope.basicAuth.username | string | `""` | Pyroscope basic auth username |
| externalServices.pyroscope.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret |
| externalServices.pyroscope.externalLabels | object | `{}` | Custom labels to be added to all profiles. All values are treated as strings and automatically quoted. |
| externalServices.pyroscope.externalLabelsFrom | object | `{}` | Custom labels to be added to all profiles through a dynamic reference. All values are treated as raw strings and not quoted. |
| externalServices.pyroscope.extraHeaders | object | `{}` | Extra headers to be set when sending metrics. All values are treated as strings and automatically quoted. |
| externalServices.pyroscope.extraHeadersFrom | object | `{}` | Extra headers to be set when sending metrics through a dynamic reference. All values are treated as raw strings and not quoted. |
| externalServices.pyroscope.host | string | `""` | Pyroscope host where profiles will be sent |
| externalServices.pyroscope.hostKey | string | `"host"` | The key for the host property in the secret |
| externalServices.pyroscope.proxyURL | string | `""` | HTTP proxy to proxy requests to Pyroscope through. |
| externalServices.pyroscope.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. |
| externalServices.pyroscope.secret.name | string | `""` | The name of the secret. |
| externalServices.pyroscope.secret.namespace | string | `""` | The namespace of the secret. |
| externalServices.pyroscope.tenantId | string | `""` | Pyroscope tenant ID |
| externalServices.pyroscope.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret |
| externalServices.pyroscope.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/pyroscope.write/#tls_config-block) to configure for the profiles service. |

### External Services (Tempo)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| externalServices.tempo.authMode | string | `"basic"` | one of "none", "basic" |
| externalServices.tempo.basicAuth.password | string | `""` | Tempo basic auth password |
| externalServices.tempo.basicAuth.passwordKey | string | `"password"` | The key for the password property in the secret |
| externalServices.tempo.basicAuth.username | string | `""` | Tempo basic auth username |
| externalServices.tempo.basicAuth.usernameKey | string | `"username"` | The key for the username property in the secret |
| externalServices.tempo.extraHeaders | object | `{}` | Extra headers to be set when sending metrics. All values are treated as strings and automatically quoted. |
| externalServices.tempo.extraHeadersFrom | object | `{}` | Extra headers to be set when sending metrics through a dynamic reference. All values are treated as raw strings and not quoted. |
| externalServices.tempo.host | string | `""` | Tempo host where traces will be sent |
| externalServices.tempo.hostKey | string | `"host"` | The key for the host property in the secret |
| externalServices.tempo.protocol | string | `"otlp"` | The type of server protocol for writing metrics Options:   * "otlp" will use OTLP   * "otlphttp" will use OTLP HTTP |
| externalServices.tempo.searchEndpoint | string | `"/api/search"` | Tempo search endpoint. |
| externalServices.tempo.secret.create | bool | `true` | Should this Helm chart create the secret. If false, you must define the name and namespace values. |
| externalServices.tempo.secret.name | string | `""` | The name of the secret. |
| externalServices.tempo.secret.namespace | string | `""` | The namespace of the secret. |
| externalServices.tempo.tenantId | string | `""` | Tempo tenant ID |
| externalServices.tempo.tenantIdKey | string | `"tenantId"` | The key for the tenant ID property in the secret |
| externalServices.tempo.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.exporter.otlp/#tls-block) to configure for the traces service. |
| externalServices.tempo.tlsOptions | string | `""` | Define the [TLS block](https://grafana.com/docs/alloy/latest/reference/components/otelcol.exporter.otlp/#tls-block). Example: `tlsOptions: insecure = true` This option will be deprecated and removed soon. Please switch to `tls` and use yaml format. |

### Metrics Global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraConfig | string | `""` | Extra configuration that will be added to the Grafana Alloy configuration file. This value is templated so that you can refer to other values from this file. This cannot be used to modify the generated configuration values, only append new components. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example. |

### Image Registry

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.image.pullSecrets | list | `[]` | Optional set of global image pull secrets. |
| global.image.registry | string | `""` | Global image registry to use if it needs to be overridden for some specific use cases (e.g local registries, custom images, ...) |

### Deployment: Kepler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kepler.enabled | bool | `false` | Should this Helm chart deploy Kepler to the cluster. Set this to false if your cluster already has Kepler, or if you do not want to scrape metrics from Kepler. |

### Deployment: [Kube State Metrics](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-state-metrics.enabled | bool | `true` | Should this helm chart deploy Kube State Metrics to the cluster. Set this to false if your cluster already has Kube State Metrics, or if you do not want to scrape metrics from Kube State Metrics. |
| kube-state-metrics.metricLabelsAllowlist | list | `["nodes=[*]"]` | `kube_<resource>_labels` metrics to generate. |

### Logs Scrape: Cluster Events

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.cluster_events.enabled | bool | `true` | Scrape Kubernetes cluster events |
| logs.cluster_events.extraConfig | string | `""` | Extra configuration that will be added to the Grafana Alloy for Cluster Events configuration file. This value is templated so that you can refer to other values from this file. This cannot be used to modify the generated configuration values, only append new components. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example. |
| logs.cluster_events.extraStageBlocks | string | `""` | Stage blocks to be added to the loki.process component for cluster events. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| logs.cluster_events.logFormat | string | `"logfmt"` | Log format used to forward cluster events. Allowed values: `logfmt` (default), `json`. |
| logs.cluster_events.logToStdout | bool | `false` | Logs the cluster events to stdout. Useful for debugging. |
| logs.cluster_events.namespaces | list | `[]` | List of namespaces to watch for events (`[]` means all namespaces) |

### Logs Global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.enabled | bool | `true` | Capture and forward logs |
| logs.extraConfig | string | `""` | Extra configuration that will be added to the Grafana Alloy for Logs configuration file. This value is templated so that you can refer to other values from this file. This cannot be used to modify the generated configuration values, only append new components. See [Adding custom Flow configuration](#adding-custom-flow-configuration) for an example. |

### Logs Scrape: Journal

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.journal.enabled | bool | `false` | Scrape Kubernetes Worker Journal Logs event |
| logs.journal.extraStageBlocks | string | `""` | Stage blocks to be added to the loki.process component for journal logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| logs.journal.formatAsJson | bool | `false` | Whether to forward the original journal entry as JSON. |
| logs.journal.jobLabel | string | `"integrations/kubernetes/journal"` | The value for the job label for journal logs |
| logs.journal.maxAge | string | `"8h"` | The path to the journal logs on the worker node |
| logs.journal.path | string | `"/var/log/journal"` | The path to the journal logs on the worker node |
| logs.journal.units | list | `[]` | The list of systemd units to keep scraped logs from.  If empty, all units are scraped. |

### Logs Scrape: Pod Logs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.journal.extraRelabelingRules | string | `""` | Rule blocks to be added used with the loki.source.journal component for journal logs. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) **Note:** Many field names from journald start with an `_`, such as `_systemd_unit`. The final internal label name would be `__journal__systemd_unit`, with two underscores between `__journal` and `systemd_unit`. |
| logs.pod_logs.annotation | string | `"k8s.grafana.com/logs.autogather"` | Pod annotation to use for controlling log discovery. |
| logs.pod_logs.annotations | object | `{"job":"k8s.grafana.com/logs.job"}` | Loki labels to set with values copied from the Kubernetes Pod annotations. Format: `<loki_label>: <kubernetes_annotation>`. |
| logs.pod_logs.discovery | string | `"all"` | Controls the behavior of discovering pods for logs. |
| logs.pod_logs.enabled | bool | `true` | Capture and forward logs from Kubernetes pods |
| logs.pod_logs.excludeNamespaces | list | `[]` | Do not capture logs from any pods in these namespaces. |
| logs.pod_logs.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for pod logs. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| logs.pod_logs.extraStageBlocks | string | `""` | Stage blocks to be added to the loki.process component for pod logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| logs.pod_logs.gatherMethod | string | `"volumes"` | Controls the behavior of gathering pod logs. When set to `volumes`, Grafana Alloy will use HostPath volume mounts on the cluster nodes to access the pod log files directly. When set to `api`, Grafana Alloy will access pod logs via the API server. This method may be preferable if your cluster prevents DaemonSets, HostPath volume mounts, or for other reasons. |
| logs.pod_logs.labels | object | `{"app_kubernetes_io_name":"app.kubernetes.io/name"}` | Loki labels to set with values copied from the Kubernetes Pod labels. Format: `<loki_label>: <kubernetes_label>`. |
| logs.pod_logs.namespaces | list | `[]` | Only capture logs from pods in these namespaces (`[]` means all namespaces). |
| logs.pod_logs.structuredMetadata | object | `{}` | List of labels to turn into structured metadata. If your Loki instance does not support structured metadata, leave this empty. Format: `<structured metadata>: <Loki label>`. |

### Logs Scrape: PodLog Objects

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.podLogsObjects.enabled | bool | `false` | Enable discovery of Grafana Alloy PodLogs objects. |
| logs.podLogsObjects.extraStageBlocks | string | `""` | Stage blocks to be added to the loki.process component for logs gathered via PodLogs objects. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| logs.podLogsObjects.namespaces | list | `[]` | Which namespaces to look for PodLogs objects. |
| logs.podLogsObjects.selector | string | `""` | Selector to filter which PodLogs objects to use. |

### Logs Receiver

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| logs.receiver.filters | object | `{"log_record":[]}` | Apply a filter to logs received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.filter/)) |
| logs.receiver.transforms | object | `{"labels":["cluster","namespace","job","pod"],"log":[],"resource":[]}` | Apply a transformation to logs received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.transform/)) |
| logs.receiver.transforms.labels | list | `["cluster","namespace","job","pod"]` | The list of labels to set in the Loki log stream. |
| logs.receiver.transforms.log | list | `[]` | Log transformation rules. |
| logs.receiver.transforms.resource | list | `[]` | Resource transformation rules. |

### Metrics Job: Alloy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.alloy.enabled | bool | `true` | Scrape metrics from Grafana Alloy |
| metrics.alloy.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Grafana Alloy. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.alloy.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Grafana Alloy. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.alloy.labelMatchers | object | `{"app.kubernetes.io/name":"alloy.*"}` | Label matchers used by Grafana Alloy to select Grafana Alloy pods |
| metrics.alloy.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.alloy.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.alloy.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.alloy.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Grafana Alloy to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metrics.alloy.metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from Grafana Alloy to the minimal set required for Kubernetes Monitoring as well as the Grafana Alloy integration. |
| metrics.alloy.scrapeInterval | string | 60s | How frequently to scrape metrics from Grafana Alloy. Overrides metrics.scrapeInterval |

### Metrics Job: Alloy Modules

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.alloyModules.connections | list | `[]` | List of connection configurations used by modules.  Configures the import.git component ([docs](https://grafana.com/docs/alloy/latest/reference/components/import.git/) <br>-   `alias: ""` the alias of the connection <br>-   `repository: ""` URL of the Git repository containing the module. <br>-   `revision: ""` Branch, tag, or commit to be checked out. <br>-   `pull_frequency: 15m` How often the module should check for updates. <br>-   `default: true` If true, this connection is used as the default when none is specified. <br>-   `basic_auth: {}` Credentials for basic authentication if needed. ([docs](https://grafana.com/docs/alloy/latest/reference/config-blocks/import.git/#basic_auth-block)) <br>-   `ssh_key: {}` Provides SSH key details for secure connections. ([docs](https://grafana.com/docs/alloy/latest/reference/config-blocks/import.git/#ssh_key-block)) |
| metrics.alloyModules.modules | list | `[]` | List of Modules to import.  Each module is expected to have a "kubernetes" module and a "scrape" component. Each module can have the following properties: <br>-   `name: ""` the name to use for the module. *note:* this is automatically prefixed with module_ to avoid conflicts with core components <br>-   `path: ""` the path to the alloy module <br>-   `connection: ""` (optional) the alias of the connection to use, if not specified the default connection is used <br>-   `targets: {}` (optional) Additional arguments to be passed to the modules kubernetes component <br>-   `scrape: {}` (optional) Additional arguments to be passed to the modules scrape component <br>-   `extraRelabelingRules: ""` additional relabeling rules for the discovery.relabel component <br>-   `extraMetricRelabelingRules:` additional relabeling rules for the prometheus.relabel component |

### Metrics Job: ApiServer

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.apiserver.enabled | bool | `false` | Scrape metrics from the API Server |
| metrics.apiserver.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the API Server. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.apiserver.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the API Server. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.apiserver.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.apiserver.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.apiserver.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| metrics.apiserver.scrapeInterval | string | 60s | How frequently to scrape metrics from the API Server Overrides metrics.scrapeInterval |

### Metrics Job: Auto-Discovery

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.autoDiscover.annotations.instance | string | `"k8s.grafana.com/instance"` | Annotation for overriding the instance label |
| metrics.autoDiscover.annotations.job | string | `"k8s.grafana.com/job"` | Annotation for overriding the job label |
| metrics.autoDiscover.annotations.metricsPath | string | `"k8s.grafana.com/metrics.path"` | Annotation for setting or overriding the metrics path. If not set, it defaults to /metrics |
| metrics.autoDiscover.annotations.metricsPortName | string | `"k8s.grafana.com/metrics.portName"` | Annotation for setting the metrics port by name. |
| metrics.autoDiscover.annotations.metricsPortNumber | string | `"k8s.grafana.com/metrics.portNumber"` | Annotation for setting the metrics port by number. |
| metrics.autoDiscover.annotations.metricsScheme | string | `"k8s.grafana.com/metrics.scheme"` | Annotation for setting the metrics scheme, default: http. |
| metrics.autoDiscover.annotations.metricsScrapeInterval | string | `"k8s.grafana.com/metrics.scrapeInterval"` | Annotation for overriding the scrape interval for this service or pod. Value should be a duration like "15s, 1m". Overrides metrics.autoDiscover.scrapeInterval |
| metrics.autoDiscover.annotations.scrape | string | `"k8s.grafana.com/scrape"` | Annotation for enabling scraping for this service or pod. Value should be either "true" or "false" |
| metrics.autoDiscover.bearerToken | object | `{"enabled":true}` | Sets bearer_token_file line in the prometheus.scrape annotation_autodiscovery. |
| metrics.autoDiscover.enabled | bool | `true` | Enable annotation-based auto-discovery |
| metrics.autoDiscover.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for auto-discovered entities. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.autoDiscover.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for auto-discovered entities. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.autoDiscover.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.autoDiscover.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.autoDiscover.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| metrics.autoDiscover.scrapeInterval | string | 60s | How frequently to scrape metrics from auto-discovered entities. Overrides metrics.scrapeInterval |

### Metrics Job: Beyla

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.beyla.enabled | bool | `false` | Scrape auto-instrumentation metrics from Beyla |
| metrics.beyla.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Beyla. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no __meta* labels are present. |
| metrics.beyla.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Beyla. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.beyla.labelMatchers | object | `{"app.kubernetes.io/name":"beyla"}` | Label matchers used to select the Beyla pods |
| metrics.beyla.maxCacheSize | string | 100000 | Sets the max_cache_size for the prometheus.relabel component for Beyla. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.beyla.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.beyla.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.beyla.scrapeInterval | string | 60s | How frequently to scrape metrics from Beyla. Overrides metrics.scrapeInterval |

### Metrics Job: cAdvisor

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.cadvisor.enabled | bool | `true` | Scrape container metrics from cAdvisor |
| metrics.cadvisor.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for cAdvisor. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. # ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.cadvisor.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for cAdvisor. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.cadvisor.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.cadvisor.metricsTuning.dropEmptyContainerLabels | bool | `true` | Drop metrics that have an empty container label |
| metrics.cadvisor.metricsTuning.dropEmptyImageLabels | bool | `true` | Drop metrics that have an empty image label |
| metrics.cadvisor.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.cadvisor.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.cadvisor.metricsTuning.keepPhysicalFilesystemDevices | list | `["mmcblk.p.+","nvme.+","rbd.+","sd.+","vd.+","xvd.+","dasd.+"]` | Only keep filesystem metrics that use the following physical devices |
| metrics.cadvisor.metricsTuning.keepPhysicalNetworkDevices | list | `["en[ospx][0-9].*","wlan[0-9].*","eth[0-9].*"]` | Only keep network metrics that use the following physical devices |
| metrics.cadvisor.metricsTuning.normalizeUnnecessaryLabels | list | `[{"labels":["boot_id","system_uuid"],"metric":"machine_memory_bytes"}]` | Normalize labels to the same value for the given metric and label pairs |
| metrics.cadvisor.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from cAdvisor to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metrics.cadvisor.nodeAddressFormat | string | `"direct"` | How to access the node services, either direct (use node IP, requires nodes/metrics) or via proxy (requires nodes/proxy) |
| metrics.cadvisor.scrapeInterval | string | 60s | How frequently to scrape metrics from cAdvisor. Overrides metrics.scrapeInterval |

### Metrics Job: OpenCost

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.cost.enabled | bool | `true` | Scrape cost metrics from OpenCost |
| metrics.cost.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for OpenCost. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.cost.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for OpenCost. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.cost.labelMatchers | object | `{"app.kubernetes.io/name":"opencost"}` | Label matchers used to select the OpenCost service |
| metrics.cost.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.cost.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.cost.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.cost.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from OpenCost to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metrics.cost.scrapeInterval | string | 60s | How frequently to scrape metrics from OpenCost. Overrides metrics.scrapeInterval |

### Metrics Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.enabled | bool | `true` | Capture and forward metrics |
| metrics.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for all metric sources. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for all metric sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| metrics.scrapeInterval | string | `"60s"` | How frequently to scrape metrics |

### Metrics Job: Kepler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.kepler.enabled | bool | `false` | Scrape energy metrics from Kepler |
| metrics.kepler.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kepler. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no __meta* labels are present. |
| metrics.kepler.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kepler. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with __ (i.e. __meta_kubernetes*) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.kepler.labelMatchers | object | `{"app.kubernetes.io/name":"kepler"}` | Label matchers used to select the Kepler pods |
| metrics.kepler.maxCacheSize | string | 100000 | Sets the max_cache_size for the prometheus.relabel component for Kepler. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.kepler.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.kepler.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.kepler.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kepler to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metrics.kepler.scrapeInterval | string | 60s | How frequently to scrape metrics from Kepler. Overrides metrics.scrapeInterval |

### Metrics Job: Kube State Metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.kube-state-metrics.enabled | bool | `true` | Scrape cluster object metrics from Kube State Metrics |
| metrics.kube-state-metrics.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kube State Metrics. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kube-state-metrics.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kube State Metrics. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.kube-state-metrics.labelMatchers | object | `{"app.kubernetes.io/name":"kube-state-metrics"}` | Label matchers used by Grafana Alloy to select the Kube State Metrics service |
| metrics.kube-state-metrics.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.kube-state-metrics.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.kube-state-metrics.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.kube-state-metrics.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Kube State Metrics to a useful, minimal set. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metrics.kube-state-metrics.scrapeInterval | string | 60s | How frequently to scrape metrics from Kube State Metrics. Overrides metrics.scrapeInterval |
| metrics.kube-state-metrics.service.isTLS | bool | `false` | Does this port use TLS? |
| metrics.kube-state-metrics.service.port | string | `"http"` | Name of the metrics port |

### Metrics Job: Kube Controller Manager

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.kubeControllerManager.enabled | bool | `false` | Scrape metrics from the Kube Controller Manager |
| metrics.kubeControllerManager.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Controller Manager. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kubeControllerManager.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Controller Manager. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.kubeControllerManager.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.kubeControllerManager.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.kubeControllerManager.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| metrics.kubeControllerManager.port | int | `10257` | Port number used by the Kube Controller Manager, set by `--secure-port.` |
| metrics.kubeControllerManager.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Controller Manager Overrides metrics.scrapeInterval |

### Metrics Job: Kube Proxy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.kubeProxy.enabled | bool | `false` | Scrape metrics from the Kube Proxy |
| metrics.kubeProxy.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Proxy. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kubeProxy.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Proxy. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.kubeProxy.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.kubeProxy.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.kubeProxy.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| metrics.kubeProxy.port | int | `10249` | Port number used by the Kube Proxy, set in `--metrics-bind-address`. |
| metrics.kubeProxy.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Proxy Overrides metrics.scrapeInterval |

### Metrics Job: Kube Scheduler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.kubeScheduler.enabled | bool | `false` | Scrape metrics from the Kube Scheduler |
| metrics.kubeScheduler.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for the Kube Scheduler. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kubeScheduler.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for the Kube Scheduler. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.kubeScheduler.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.kubeScheduler.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.kubeScheduler.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. An empty list means keep all. |
| metrics.kubeScheduler.port | int | `10259` | Port number used by the Kube Scheduler, set by `--secure-port`. |
| metrics.kubeScheduler.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kube Scheduler Overrides metrics.scrapeInterval |

### Metrics Job: Kubelet

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.kubelet.enabled | bool | `true` | Scrape cluster metrics from the Kubelet |
| metrics.kubelet.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Kubelet. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.kubelet.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Kubelet. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.kubelet.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.kubelet.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.kubelet.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.kubelet.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from the Kubelet to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metrics.kubelet.nodeAddressFormat | string | `"direct"` | How to access the node services, either direct (use node IP, requires nodes/metrics) or via proxy (requires nodes/proxy) |
| metrics.kubelet.scrapeInterval | string | 60s | How frequently to scrape metrics from the Kubelet. Overrides metrics.scrapeInterval |

### Metrics Job: Kubernetes Monitoring Telemetry

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.kubernetesMonitoring.enabled | bool | `true` | Report telemetry about this Kubernetes Monitoring chart as a metric. |
| metrics.kubernetesMonitoring.scrapeInterval | string | 60s | How frequently to scrape the telemetry report metric. Overrides metrics.scrapeInterval |

### Metrics Job: Node Exporter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.node-exporter.enabled | bool | `true` | Scrape node metrics |
| metrics.node-exporter.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Node Exporter. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.node-exporter.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Node Exporter. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.node-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"prometheus-node-exporter.*"}` | Label matchers used to select the Node exporter pods |
| metrics.node-exporter.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.node-exporter.metricsTuning.dropMetricsForFilesystem | list | `["tempfs"]` | Drop metrics for the given filesystem types |
| metrics.node-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.node-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.node-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metrics.node-exporter.metricsTuning.useIntegrationAllowList | bool | `false` | Filter the list of metrics from Node Exporter to the minimal set required for Kubernetes Monitoring as well as the Node Exporter integration. |
| metrics.node-exporter.scrapeInterval | string | 60s | How frequently to scrape metrics from Node Exporter. Overrides metrics.scrapeInterval |
| metrics.node-exporter.service.isTLS | bool | `false` | Does this port use TLS? |

### Metrics Job: Prometheus Operator (PodMonitors)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.podMonitors.enabled | bool | `true` | Enable discovery of Prometheus Operator PodMonitor objects. |
| metrics.podMonitors.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for PodMonitor objects. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.podMonitors.extraRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.operator.podmonitors component for PodMonitors. These relabeling rules are applied pre-scrape against the targets from service discovery. The relabelings defined in the PodMonitor object are applied first, then these relabelings are applied. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.podMonitors.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.podMonitors.namespaces | list | `[]` | Which namespaces to look for PodMonitor objects. |
| metrics.podMonitors.scrapeInterval | string | 60s | How frequently to scrape metrics from PodMonitor objects. Only used if the PodMonitor does not specify the scrape interval. Overrides metrics.scrapeInterval |
| metrics.podMonitors.selector | string | `""` | Selector to filter which PodMonitor objects to use. |

### Metrics Job: Prometheus Operator (Probes)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.probes.enabled | bool | `true` | Enable discovery of Prometheus Operator Probe objects. |
| metrics.probes.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Probe objects. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.probes.extraRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.operator.probes component for Probes. These relabeling rules are applied pre-scrape against the targets from service discovery. The relabelings defined in the PodMonitor object are applied first, then these relabelings are applied. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.probes.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.probes.namespaces | list | `[]` | Which namespaces to look for Probe objects. |
| metrics.probes.scrapeInterval | string | 60s | How frequently to scrape metrics from Probe objects. Only used if the Probe does not specify the scrape interval. Overrides metrics.scrapeInterval |
| metrics.probes.selector | string | `""` | Selector to filter which Probes objects to use. |

### Metrics Receivers

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.receiver.filters | object | `{"datapoint":[],"metric":[]}` | Apply a filter to metrics received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.filter/)) |
| metrics.receiver.transforms | object | `{"datapoint":[],"metric":[],"resource":[]}` | Apply a transformation to metrics received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.transform/)) |

### Metrics Job: Prometheus Operator (ServiceMonitors)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.serviceMonitors.enabled | bool | `true` | Enable discovery of Prometheus Operator ServiceMonitor objects. |
| metrics.serviceMonitors.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for ServiceMonitor objects. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.serviceMonitors.extraRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.operator.probes component for Probes. These relabeling rules are applied pre-scrape against the targets from service discovery. The relabelings defined in the PodMonitor object are applied first, then these relabelings are applied. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.serviceMonitors.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.serviceMonitors.namespaces | list | `[]` | Which namespaces to look for ServiceMonitor objects. |
| metrics.serviceMonitors.scrapeInterval | string | 60s | How frequently to scrape metrics from ServiceMonitor objects. Only used if the ServiceMonitor does not specify the scrape interval. Overrides metrics.scrapeInterval |
| metrics.serviceMonitors.selector | string | `""` | Selector to filter which ServiceMonitor objects to use. |

### Metrics Job: Windows Exporter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.windows-exporter.enabled | bool | `false` | Scrape node metrics |
| metrics.windows-exporter.extraMetricRelabelingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for Windows Exporter. These relabeling rules are applied post-scrape against the metrics returned from the scraped target, no `__meta*` labels are present. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#rule-block)) |
| metrics.windows-exporter.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Windows Exporter. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| metrics.windows-exporter.labelMatchers | object | `{"app.kubernetes.io/name":"prometheus-windows-exporter.*"}` | Label matchers used to select the Windows Exporter pods |
| metrics.windows-exporter.maxCacheSize | string | `nil` | Sets the max_cache_size for cadvisor prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) Overrides metrics.maxCacheSize |
| metrics.windows-exporter.metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.windows-exporter.metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| metrics.windows-exporter.metricsTuning.useDefaultAllowList | bool | `true` | Filter the list of metrics from Windows Exporter to the minimal set required for Kubernetes Monitoring. See [Metrics Tuning and Allow Lists](#metrics-tuning-and-allow-lists) |
| metrics.windows-exporter.scrapeInterval | string | 60s | How frequently to scrape metrics from Windows Exporter. Overrides metrics.scrapeInterval |

### Deployment: [OpenCost](https://github.com/opencost/opencost-helm-chart)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| opencost.enabled | bool | `true` | Should this Helm chart deploy OpenCost to the cluster. Set this to false if your cluster already has OpenCost, or if you do not want to scrape metrics from OpenCost. |
| opencost.opencost.prometheus.existingSecretName | string | `"prometheus-k8s-monitoring"` | The name of the secret containing the username and password for the metrics service. This must be in the same namespace as the OpenCost deployment. |
| opencost.opencost.prometheus.password_key | string | `"password"` | The key for the password property in the secret. |
| opencost.opencost.prometheus.username_key | string | `"username"` | The key for the username property in the secret. |

### Deployment: [OpenCost](https://github.com/opencost/opencost-helm-chart)3

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| opencost.opencost.prometheus.external.url | string | `"https://prom.example.com/api/prom"` | The URL for Prometheus queries. It should match externalServices.prometheus.host + "/api/prom" |

### Profiles (eBPF)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| profiles.ebpf.demangle | string | `"none"` | C++ demangle mode. Available options are: none, simplified, templates, full |
| profiles.ebpf.enabled | bool | `true` | Gather profiles using eBPF |
| profiles.ebpf.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| profiles.ebpf.namespaces | list | `[]` | Which namespaces to look for pods with profiles. |

### Profiles

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| profiles.enabled | bool | `false` | Receive and forward profiles. |

### Profiles (java)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| profiles.java.enabled | bool | `true` | Gather profiles by scraping java HTTP endpoints |
| profiles.java.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Java profile sources. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| profiles.java.namespaces | list | `[]` | Which namespaces to look for pods with profiles. |
| profiles.java.profilingConfig | object | `{"alloc":"512k","cpu":true,"interval":"60s","lock":"10ms","sampleRate":100}` | Configuration for the async-profiler |

### Profiles (pprof)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| profiles.pprof.enabled | bool | `true` | Gather profiles by scraping pprof HTTP endpoints |
| profiles.pprof.extraRelabelingRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/#rule-block)) |
| profiles.pprof.namespaces | list | `[]` | Which namespaces to look for pods with profiles. |
| profiles.pprof.types | list | `["memory","cpu","goroutine","block","mutex","fgprof"]` | Profile types to gather |

### Deployment: [Prometheus Node Exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| prometheus-node-exporter.enabled | bool | `true` | Should this helm chart deploy Node Exporter to the cluster. Set this to false if your cluster already has Node Exporter, or if you do not want to scrape metrics from Node Exporter. |

### Deployment: [Prometheus Operator CRDs](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-operator-crds)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| prometheus-operator-crds.enabled | bool | `true` | Should this helm chart deploy the Prometheus Operator CRDs to the cluster. Set this to false if your cluster already has the CRDs, or if you do not to have Grafana Alloy scrape metrics from PodMonitors, Probes, or ServiceMonitors. |

### Deployment: [Prometheus Windows Exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-windows-exporter)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| prometheus-windows-exporter.enabled | bool | `false` | Should this helm chart deploy Windows Exporter to the cluster. Set this to false if your cluster already has Windows Exporter, or if you do not want to scrape metrics from Windows Exporter. |

### OTEL Receivers

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.deployGrafanaAgentService | bool | `true` | Deploy a service named for Grafana Agent that matches the Alloy service. This is useful for applications that are configured to send telemetry to a service named "grafana-agent" and not yet updated to send to "alloy". |

### OTEL Receivers (Processors)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.grafanaCloudMetrics.enabled | bool | `true` | Generate host info metrics from telemetry data, used in Application Observability in Grafana Cloud. |
| receivers.processors.batch.maxSize | int | `0` | The upper limit of the amount of data contained in a single batch, in bytes. When set to 0, batches can be any size. |
| receivers.processors.batch.size | int | `16384` | What batch size to use, in bytes |
| receivers.processors.batch.timeout | string | `"2s"` | How long before sending (Processors) |
| receivers.processors.k8sattributes.annotations | list | `[]` | Kubernetes annotations to extract and add to the attributes of the received telemetry data. |
| receivers.processors.k8sattributes.labels | list | `[]` | Kubernetes labels to extract and add to the attributes of the received telemetry data. |
| receivers.processors.k8sattributes.metadata | list | `["k8s.namespace.name","k8s.pod.name","k8s.deployment.name","k8s.statefulset.name","k8s.daemonset.name","k8s.cronjob.name","k8s.job.name","k8s.node.name","k8s.pod.uid","k8s.pod.start_time"]` | Kubernetes metadata to extract and add to the attributes of the received telemetry data. |

### OTEL Receivers (gRPC)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.grpc.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. |
| receivers.grpc.enabled | bool | `true` | Receive OpenTelemetry signals over OTLP/gRPC? |
| receivers.grpc.port | int | `4317` | Which port to use for the OTLP/gRPC receiver. This port needs to be opened in the alloy section below. |
| receivers.grpc.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.receiver.otlp/#tls-block) to configure for the OTLP/gRPC receiver. |

### OTEL Receivers (HTTP)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.http.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. |
| receivers.http.enabled | bool | `true` | Receive OpenTelemetry signals over OTLP/HTTP? |
| receivers.http.port | int | `4318` | Which port to use for the OTLP/HTTP receiver. This port needs to be opened in the alloy section below. |
| receivers.http.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.receiver.otlp/#tls-block) to configure for the OTLP/HTTP receiver. |

### OTEL Receivers (Jaeger)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.jaeger.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. |
| receivers.jaeger.grpc.enabled | bool | `false` | Receive Jaeger signals via gRPC protocol. |
| receivers.jaeger.grpc.port | int | `14250` | Which port to use for the Jaeger gRPC receiver. This port needs to be opened in the alloy section below. |
| receivers.jaeger.thriftBinary.enabled | bool | `false` | Receive Jaeger signals via Thrift binary protocol. |
| receivers.jaeger.thriftBinary.port | int | `6832` | Which port to use for the Thrift binary receiver. This port needs to be opened in the alloy section below. |
| receivers.jaeger.thriftCompact.enabled | bool | `false` | Receive Jaeger signals via Thrift compact protocol. |
| receivers.jaeger.thriftCompact.port | int | `6831` | Which port to use for the Thrift compact receiver. This port needs to be opened in the alloy section below. |
| receivers.jaeger.thriftHttp.enabled | bool | `false` | Receive Jaeger signals via Thrift HTTP protocol. |
| receivers.jaeger.thriftHttp.port | int | `14268` | Which port to use for the Thrift HTTP receiver. This port needs to be opened in the alloy section below. |
| receivers.jaeger.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.receiver.jaeger/#tls-block) to configure for the Jaeger receiver. |

### OTEL Receivers (Prometheus)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.prometheus.enabled | bool | `false` | Receive Prometheus metrics |
| receivers.prometheus.port | int | `9999` | Which port to use for the Prometheus receiver. This port needs to be opened in the alloy section below. |

### OTEL Receivers (Zipkin)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| receivers.zipkin.disable_debug_metrics | bool | `true` | It removes attributes which could cause high cardinality metrics. For example, attributes with IP addresses and port numbers in metrics about HTTP and gRPC connections will be removed. |
| receivers.zipkin.enabled | bool | `false` | Receive Zipkin traces |
| receivers.zipkin.port | int | `9411` | Which port to use for the Zipkin receiver. This port needs to be opened in the alloy section below. |
| receivers.zipkin.tls | object | `{}` | [TLS settings](https://grafana.com/docs/alloy/latest/reference/components/otelcol.receiver.zipkin/#tls-block) to configure for the Zipkin receiver. |

### Test Job

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| test.attempts | int | `10` | How many times to attempt the test job. |
| test.enabled | bool | `true` | Should `helm test` run the test job? |
| test.envOverrides | object | `{"LOKI_URL":"","PROFILECLI_URL":"","PROMETHEUS_URL":"","TEMPO_URL":""}` | Overrides the URLs for various data sources |
| test.extraAnnotations | object | `{}` | Extra annotations to add to the test job. |
| test.extraLabels | object | `{}` | Extra labels to add to the test job. |
| test.extraQueries | list | `[]` | Additional queries to run during the test. See the [Helm tests docs](./docs/HelmTests.md) for more information. |
| test.image.image | string | `"grafana/k8s-monitoring-test"` | Test job image repository. |
| test.image.pullSecrets | list | `[]` | Optional set of image pull secrets. |
| test.image.registry | string | `"ghcr.io"` | Test job image registry. |
| test.image.tag | string | `""` | Test job image tag. Default is the chart version. |
| test.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | nodeSelector to apply to the test job. |
| test.serviceAccount | object | `{"name":""}` | Service Account to use for the test job. |
| test.tolerations | list | `[]` | Tolerations to apply to the test job. |

### Traces

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| traces.enabled | bool | `false` | Receive and forward traces. |
| traces.receiver.filters | object | `{"span":[],"spanevent":[]}` | Apply a filter to traces received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.filter/)) |
| traces.receiver.transforms | object | `{"resource":[],"span":[],"spanevent":[]}` | Apply a transformation to traces received via the OTLP or OTLP HTTP receivers. ([docs](https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.transform/)) |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraObjects | list | `[]` | Deploy additional manifest objects |

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
