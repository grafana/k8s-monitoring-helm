<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring-feature-integrations

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)
Service integrations

The Integrations feature builds in configuration for many common applications and services.

The current integrations that are available from this feature are:

| Integration | Description | Data Types | Docs |
| --- | --- | --- | --- |
| [Grafana Alloy](https://grafana.com/docs/alloy) | Telemetry data collector | Metrics | [Docs](./docs/integrations/alloy.md) |
| [cert-manager](https://cert-manager.io/) | x.509 certificate management for Kubernetes | Metrics | [Docs](./docs/integrations/cert-manager.md) |
| [etcd](https://etcd.io/) | Distributed key-value store | Metrics | [Docs](./docs/integrations/etcd.md) |

## Usage

To enable an integration, create an instance of it, with any configuration to aid in service discovery. For example:

```yaml
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

For all possible values for a specific integration, see the [documentation](./docs) page for that integration.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-integrations>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Integration: Alloy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"instances":[]}` | Scrape metrics from Grafana Alloy |

### Integration: cert-manager

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cert-manager | object | `{"instances":[]}` | Scrape metrics from cert-manager |

### Integration: etcd

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| etcd | object | `{"instances":[]}` | Scrape metrics from etcd |

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |
