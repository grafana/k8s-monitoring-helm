<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# feature-profiling

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)
Gathers profiles from eBPF, Java, and pprof sources.

The Profiling feature enables the collection of profiles from the processes running in the cluster.

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `deployAsConfigMap` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-profiling>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### eBPF

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ebpf.demangle | string | `"none"` | C++ demangle mode. Available options are: none, simplified, templates, full |
| ebpf.enabled | bool | `true` | Gather profiles using eBPF |
| ebpf.excludeNamespaces | list | `[]` | Which namespaces to exclude looking for pods. |
| ebpf.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| ebpf.namespaces | list | `[]` | Which namespaces to look for pods with profiles. |

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |

### Java

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| java.enabled | bool | `true` | Gather profiles by scraping java HTTP endpoints |
| java.excludeNamespaces | list | `[]` | Which namespaces to exclude looking for pods. |
| java.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Java profile sources. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| java.namespaces | list | `[]` | Which namespaces to look for pods with profiles. |
| java.profilingConfig | object | `{"alloc":"512k","cpu":true,"interval":"60s","lock":"10ms","sampleRate":100}` | Configuration for the async-profiler |

### pprof

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pprof.enabled | bool | `true` | Gather profiles by scraping pprof HTTP endpoints |
| pprof.excludeNamespaces | list | `[]` | Which namespaces to exclude looking for pods. |
| pprof.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| pprof.namespaces | list | `[]` | Which namespaces to look for pods with profiles. |
| pprof.types | object | `{"block":true,"cpu":true,"fgprof":true,"godeltaprof_block":false,"godeltaprof_memory":false,"godeltaprof_mutex":false,"goroutine":true,"memory":true,"mutex":true}` | Profile types to gather |
