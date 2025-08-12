<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Integrations

The Integrations feature builds in configuration for many common applications and services.

The current integrations that are available from this feature are:

| Integration | Description | Data Types | Docs |
| --- | --- | --- | --- |
| [Grafana Alloy](https://grafana.com/docs/alloy) | Telemetry data collector | Metrics | [Alloy doc](./docs/integrations/alloy.md) |
| [cert-manager](https://cert-manager.io/) | x.509 certificate management for Kubernetes | Metrics | [Cert manager doc](./docs/integrations/cert-manager.md) |
| [etcd](https://etcd.io/) | Distributed key-value store | Metrics | [etcd doc](./docs/integrations/etcd.md) |

## Usage

To enable an integration, create an instance of it with any configuration to aid in service discovery. For example:

```yaml
integrations:
  cert-manager:
    instances:
      - name: cert-manager
        namespace: kube-system
        labelSelectors:
          app.kubernetes.io/name: cert-manager
```

You can specify multiple instances of the same integration to match multiple instances of that service. For example:

```yaml
alloy:
  instances:
    - name: alloy-metrics
      labelSelectors:
        app.kubernetes.io/name: alloy-metrics
    - name: alloy-receivers
      labelSelectors:
        app.kubernetes.io/name: alloy-receivers
```

For all possible values for a specific integration, refer to the previous table for the link to the integration documentation.

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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-integrations>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

<!-- textlint-disable terminology -->
## Values

### Integration: Alloy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"instances":[]}` | Scrape metrics/logs from Grafana Alloy |

### Integration: cert-manager

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cert-manager | object | `{"instances":[]}` | Scrape metrics/logs from cert-manager |

### Integration: DCGM Exporter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dcgm-exporter | object | `{"instances":[]}` | Scrape metrics/logs from DCGM Exporter |

### Integration: etcd

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| etcd | object | `{"instances":[]}` | Scrape metrics/logs from etcd |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.alloyModules.branch | string | `"main"` | If using git, the branch of the git repository to use. |
| global.alloyModules.source | string | `"git"` | The source of the Alloy modules. The valid options are "configMap" or "git" |
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |

### Integration: Grafana

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| grafana | object | `{"instances":[]}` | Scrape metrics/logs from Grafana |

### Integration: Loki

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| loki | object | `{"instances":[]}` | Scrape metrics/logs from Loki |

### Integration: Mimir

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| mimir | object | `{"instances":[]}` | Scrape metrics/logs from Mimir |

### Integration: MySQL

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| mysql | object | `{"instances":[]}` | Scrape metrics/logs from MySQL |

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

### Integration: Tempo

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tempo | object | `{"instances":[]}` | Scrape metrics/logs from Tempo |
<!-- textlint-enable terminology -->

## Contributing

To contribute integrations to this feature, you must create or modify a few files:

*   `values.yaml` - The main feature chart's values file. Add a section for your integration. It must contain an
    `instance` array and any settings that apply to every instance of the integration. For example:

    ```yaml
    <slug>:
      instances: []
      globalSetting: value
    ```

*   `integrations/<slug>-values.yaml` - The values that will be used for each instance. This must include `name` to
    differentiate it from other instances and any other settings that are specific to that instance. For example:

    ```yaml
    name: ""
    labelSelectors:
      app.kubernetes.io/name: my-service
    protocol: http
    ...
    ```

*   `templates/_integration<=_<slug>.tpl` - The file that contains template functions that build the configuration to
    discover, gather, process, and deliver the telemetry data. This file is required to implement the following template functions:
    *   `integrations.<slug>.type.metrics` - Returns true if this integration scrapes metrics.
    *   `integrations.<slug>.type.logs` - Returns true if this integration gathers logs.
    *   `integrations.<slug>.module` - Returns the configuration that is included once if this integration is used. This
        is typically the module definition.
    *   `integrations.<slug>.include.metrics` - Returns the configuration that is included for each instance of the
        integration that scrapes metrics.
    *   `integrations.<slug>.include.logs` - Returns the configuration that is included for each instance of the
        integration that gathers logs.
    *   `integrations.<slug>.exclude.logs` - Returns a rule that can be used by other Log-gathering features to ensure
        that logs that are gathered from this integration are not collected twice. Typically the inverse of a rule in
        the `integrations.<slug>.include.logs` function.
    *   `default-allow-lists/<slug>.yaml` - If the integration scrapes metrics, a common pattern is to provide a list of
        metrics that should be allowed. This reduces the amount of metrics delivered to a useful minimal set.

*   When testing changes to this chart, from `/charts/k8s-monitoring` run `rm -rf Chart.lock && make build` to force the chart to be rebuilt.
