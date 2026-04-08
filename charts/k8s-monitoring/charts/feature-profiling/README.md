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

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations.prefix | string | `"profiles.grafana.com"` | The prefix for all annotations. |

### eBPF

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ebpf.annotationSelectors | object | `{}` | Select pods to profile based on pod annotations. Example: `color: "green"` will select pods with the annotation `color="green"`. Example with multiple values: `color: ["blue", "green"]` will select pods with the annotation `color="blue"` or `color="green"`. |
| ebpf.annotations.enable | string | `"profiles.grafana.com/cpu.ebpf.enabled"` | The annotation action for enabling or disabling collecting of profiles with eBPF. |
| ebpf.demangle | string | `"none"` | C++ demangle mode. Available options are: none, simplified, templates, full |
| ebpf.dotnetEnabled | bool | `true` | A flag to enable or disable .NET profiling. |
| ebpf.enabled | bool | `false` | Gather profiles using eBPF |
| ebpf.excludeNamespaces | list | `[]` | Which namespaces to exclude looking for pods. |
| ebpf.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| ebpf.hotspotEnabled | bool | `true` | A flag to enable or disable Hotspot profiling. |
| ebpf.labelSelectors | object | `{}` | Select pods to profile based on pod labels. Example: `app.kubernetes.io/name: myapp` will select pods with the label `app.kubernetes.io/name=myapp`. Example with multiple values: `app.kubernetes.io/name: [myapp, myapp2]` will select pods with the label `app.kubernetes.io/name=myapp` or `app.kubernetes.io/name=myapp2`. |
| ebpf.namespaces | list | `[]` | Select pods to profile based on their namespaces. |
| ebpf.perlEnabled | bool | `true` | A flag to enable or disable Perl profiling. |
| ebpf.phpEnabled | bool | `true` | A flag to enable or disable PHP profiling. |
| ebpf.pythonEnabled | bool | `true` | A flag to enable or disable Python profiling. |
| ebpf.rubyEnabled | bool | `true` | A flag to enable or disable Ruby profiling. |
| ebpf.sampleRate | int | `19` | Sample rate for eBPF profiling. This controls how frequently samples are collected. |
| ebpf.targetingScheme | string | `"annotation"` | How to target pods for collecting profiles with eBPF. Options are `all` and `annotation`. If using `all`, all Kubernetes pods will be targeted for collecting profiles, and you can exclude certain pods by setting the `profiles.grafana.com/cpu.ebpf.enabled="false"` annotation on that pod. If using `annotation`, only pods with the `profiles.grafana.com/cpu.ebpf.enabled="true"` annotation will have profiles collected with eBPF. |
| ebpf.v8Enabled | bool | `true` | A flag to enable or disable V8 profiling. |

### Java

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| java.annotationSelectors | object | `{}` | Select pods to profile based on pod annotations. Example: `color: "green"` will select pods with the annotation `color="green"`. Example with multiple values: `color: ["blue", "green"]` will select pods with the annotation `color="blue"` or `color="green"`. |
| java.annotations.enable | string | `"enabled"` | The annotation action for enabling or disabling of Java profile collection. |
| java.enabled | bool | `false` | Gather profiles by attaching async-profiler to the Java runtime. |
| java.excludeNamespaces | list | `[]` | Which namespaces to exclude looking for pods. |
| java.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for Java profile sources. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| java.labelSelectors | object | `{}` | Select pods to profile based on pod labels. Example: `app.kubernetes.io/name: myapp` will select pods with the label `app.kubernetes.io/name=myapp`. Example with multiple values: `app.kubernetes.io/name: [myapp, myapp2]` will select pods with the label `app.kubernetes.io/name=myapp` or `app.kubernetes.io/name=myapp2`. |
| java.namespaces | list | `[]` | Select pods to profile based on their namespaces. |
| java.profilingConfig.alloc | string | `"512k"` | Allocation profiling sampling configuration. It's passed as an `--alloc` argument to async-profiler. |
| java.profilingConfig.cpu | bool | `true` | A flag to enable CPU profiling, using `itimer` async-profiler event by default. |
| java.profilingConfig.event | string | `"itimer"` | Sets the CPU profiling event. Can be one of `itimer`, `cpu` or `wall`. |
| java.profilingConfig.interval | string | `"60s"` | How frequently to collect profiles from the targets. |
| java.profilingConfig.lock | string | `"10ms"` | Lock profiling sampling configuration. It’s passed as a `--lock` argument to async-profiler. |
| java.profilingConfig.sampleRate | int | `100` | CPU profiling sample rate. It’s converted from Hz to interval and passed as an `-i` argument to async-profiler. |
| java.targetingScheme | string | `"annotation"` | How to target pods for finding Java profiles. Options are `all` and `annotation`. If using `all`, all Kubernetes pods will be targeted for Java profiles, and you can exclude certain pods by setting the `profiles.grafana.com/java.enabled="false"` annotation on that pod. If using `annotation`, only pods with the `profiles.grafana.com/java.enabled="true"` annotation will collecting Java profiles. |

### pprof

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pprof.annotationSelectors | object | `{}` | Select pods to profile based on pod annotations. Example: `color: "green"` will select pods with the annotation `color="green"`. Example with multiple values: `color: ["blue", "green"]` will select pods with the annotation `color="blue"` or `color="green"`. |
| pprof.annotations.container | string | `"container"` | The annotation action for choosing the container for scraping profiles of a given type. |
| pprof.annotations.enable | string | `"scrape"` | The annotation action for enabling or disabling scraping of profiles of a given type. |
| pprof.annotations.path | string | `"path"` | The annotation action for choosing the path for scraping profiles of a given type. |
| pprof.annotations.portName | string | `"port_name"` | The annotation action for choosing the port name for scraping profiles of a given type. |
| pprof.annotations.portNumber | string | `"port"` | The annotation action for choosing the port number for scraping profiles of a given type. |
| pprof.annotations.scheme | string | `"scheme"` | The annotation action for choosing the scheme for scraping profiles of a given type. |
| pprof.bearerTokenFile | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` | The bearer token file to use when scraping profiles. |
| pprof.enabled | bool | `false` | Gather profiles by scraping pprof HTTP endpoints |
| pprof.excludeNamespaces | list | `[]` | Which namespaces to exclude looking for pods. |
| pprof.extraDiscoveryRules | string | `""` | Rule blocks to be added to the discovery.relabel component for eBPF profile sources. These relabeling rules are applied pre-scrape against the targets from service discovery. Before the scrape, any remaining target labels that start with `__` (i.e. `__meta_kubernetes*`) are dropped. ([docs](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.relabel/#rule-block)) |
| pprof.labelSelectors | object | `{}` | Select pods to profile based on pod labels. Example: `app.kubernetes.io/name: myapp` will select pods with the label `app.kubernetes.io/name=myapp`. Example with multiple values: `app.kubernetes.io/name: [myapp, myapp2]` will select pods with the label `app.kubernetes.io/name=myapp` or `app.kubernetes.io/name=myapp2`. |
| pprof.namespaces | list | `[]` | Select pods to profile based on their namespaces. |
| pprof.scrapeInterval | string | `"15s"` | How frequently to collect profiles. |
| pprof.scrapeTimeout | string | `"18s"` | Timeout for collecting profiles. Must be larger than the scrape interval. |
| pprof.types | object | `{"block":true,"cpu":true,"fgprof":true,"godeltaprof_block":false,"godeltaprof_memory":false,"godeltaprof_mutex":false,"goroutine":true,"memory":true,"mutex":true}` | Profile types to gather |
