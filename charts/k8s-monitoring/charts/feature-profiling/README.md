<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Profiling

The Profiling feature enables the collection of profiles from the processes running in the cluster.

## Usage

```yaml
profiling:
  enabled: true
```

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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-profiling>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### eBPF

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ebpf.annotationSelectors | object | `{}` | Select pods to profile based on pod annotations. Example: `k8s.grafana.com/profile: "true"` will select pods with the annotation `k8s.grafana.com/profile="true"`. Example with multiple values: `color: ["blue", "green"]` will select pods with the annotation `color="blue"` or `color="green"`. |
| ebpf.demangle | string | `"none"` | C++ demangle mode. Available options are: none, simplified, templates, full |
| ebpf.enabled | bool | `true` | Gather profiles using eBPF |
| ebpf.excludeNamespaces | list | `[]` | Which namespaces to exclude looking for pods. |
| ebpf.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| ebpf.labelSelectors | object | `{}` | Select pods to profile based on pod labels. Example: `app.kubernetes.io/name: myapp` will select pods with the label `app.kubernetes.io/name=myapp`. Example with multiple values: `app.kubernetes.io/name: [myapp, myapp2]` will select pods with the label `app.kubernetes.io/name=myapp` or `app.kubernetes.io/name=myapp2`. |
| ebpf.namespaces | list | `[]` | Select pods to profile based on their namespaces. |

### Java

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| java.annotationSelectors | object | `{}` | Select pods to profile based on pod annotations. Example: `k8s.grafana.com/profile: "true"` will select pods with the annotation `k8s.grafana.com/profile="true"`. Example with multiple values: `color: ["blue", "green"]` will select pods with the annotation `color="blue"` or `color="green"`. |
| java.enabled | bool | `true` | Gather profiles by scraping java HTTP endpoints |
| java.excludeNamespaces | list | `[]` | Which namespaces to exclude looking for pods. |
| java.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Java profile sources. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| java.labelSelectors | object | `{}` | Select pods to profile based on pod labels. Example: `app.kubernetes.io/name: myapp` will select pods with the label `app.kubernetes.io/name=myapp`. Example with multiple values: `app.kubernetes.io/name: [myapp, myapp2]` will select pods with the label `app.kubernetes.io/name=myapp` or `app.kubernetes.io/name=myapp2`. |
| java.namespaces | list | `[]` | Select pods to profile based on their namespaces. |
| java.profilingConfig | object | `{"alloc":"512k","cpu":true,"interval":"60s","lock":"10ms","sampleRate":100}` | Configuration for the async-profiler |

### pprof

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pprof.annotationSelectors | object | `{}` | Select pods to profile based on pod annotations. Example: `k8s.grafana.com/profile: "true"` will select pods with the annotation `k8s.grafana.com/profile="true"`. Example with multiple values: `color: ["blue", "green"]` will select pods with the annotation `color="blue"` or `color="green"`. |
| pprof.enabled | bool | `true` | Gather profiles by scraping pprof HTTP endpoints |
| pprof.excludeNamespaces | list | `[]` | Which namespaces to exclude looking for pods. |
| pprof.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| pprof.labelSelectors | object | `{}` | Select pods to profile based on pod labels. Example: `app.kubernetes.io/name: myapp` will select pods with the label `app.kubernetes.io/name=myapp`. Example with multiple values: `app.kubernetes.io/name: [myapp, myapp2]` will select pods with the label `app.kubernetes.io/name=myapp` or `app.kubernetes.io/name=myapp2`. |
| pprof.namespaces | list | `[]` | Select pods to profile based on their namespaces. |
| pprof.scrapeInterval | string | `"15s"` | How frequently to collect profiles. |
| pprof.scrapeTimeout | string | `"18s"` | Timeout for collecting profiles. Must be larger then the scrape interval. |
| pprof.types | object | `{"block":true,"cpu":true,"fgprof":true,"godeltaprof_block":false,"godeltaprof_memory":false,"godeltaprof_mutex":false,"goroutine":true,"memory":true,"mutex":true}` | Profile types to gather |
