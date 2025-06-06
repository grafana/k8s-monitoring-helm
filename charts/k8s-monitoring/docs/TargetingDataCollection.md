# Targeting Data Collection

The Kubernetes Monitoring Helm chart allows you to target specific namespaces or pods for data collection. There are
many different methods to control this, and the following sections will explain how to use many of them.

## Kubernetes Annotations

Several features within this Helm chart can be controlled using Kubernetes annotations. Often it is for controlling
service discovery, but often annotations can be used to configure how data is collected.

### Feature: Annotation Autodiscovery

The Annotation Autodiscovery feature allows you to discover and scrape Prometheus-style metrics from Pods and Services
on your cluster. These are the default annotations that can be applied to a Pod or Service:

*   `k8s.grafana.com/scrape`: This Pod or Service should be scrape for metrics.
*   `k8s.grafana.com/job`: The value to use for the `job` label.
*   `k8s.grafana.com/instance`: The value to use for the `instance` label.
*   `k8s.grafana.com/metrics.container`: The name of the container within the Pod to scrape for metrics. This is used to target a specific container within a Pod that has multiple containers.
*   `k8s.grafana.com/metrics.path`: The path to scrape for metrics. Defaults to `/metrics`.
*   `k8s.grafana.com/metrics.portNumber`: The port on the Pod or Service to scrape for metrics. This is used to target a specific port by its number, rather than all ports.
*   `k8s.grafana.com/metrics.portName`: The named port on the Pod or Service to scrape for metrics. This is used to target a specific port by its name, rather than all ports.
*   `k8s.grafana.com/metrics.scheme`: The scheme to use when scraping metrics. Defaults to `http`.
*   `k8s.grafana.com/metrics.param`: Allows for setting HTTP parameters when calling the scrape endpoint. Use with `k8s.grafana.com/metrics.param_<key>="<value>"`.
*   `k8s.grafana.com/metrics.scrapeInterval`: The scrape interval to use when scraping metrics. Defaults to `60s`.
*   `k8s.grafana.com/metrics.scrapeTimeout`: The scrape timeout to use when scraping metrics. Defaults to `10s`.

The actual annotations can be configured in the [annotationAutodiscovery feature](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-annotation-autodiscovery).

### Feature: Profiling

The Profiling feature allows you to collect profiling data from your applications. This feature can collect profiles
using eBPF, Java, or pprof. The following annotations can be used to control profiling:

#### eBPF Profiling

*   `profiles.grafana.com/cpu.ebpf.enabled`: This Pod should have CPU profiles collected using eBPF.

#### Java Profiling

*   `profiles.grafana.com/java.enabled`: This Pod should have Java profiles collected.

#### pprof Profiling

For each enabled type (`memory`, `block`, `goroutine`, `mutex`, `cpu`, `fgprof`, `godeltaprof_memory`,
`godeltaprof_mutex`, `godeltaprof_block`), you can use the following annotations to control profiling:

*   `profiles.grafana.com/<type>.scrape`: This Pod should have pprof profiles collected for the specified type.
*   `profiles.grafana.com/<type>.port`: Profiles for the specified type should be collected from this port number.
*   `profiles.grafana.com/<type>.port_name`: Profiles for the specified type should be collected from this named port.
*   `profiles.grafana.com/<type>.path`: Profiles for the specified type should be collected from this path.
*   `profiles.grafana.com/<type>.scheme`: The scheme to use when scraping profiles for the specified type. Defaults to `http`.

### Feature: Pod Logs

The following annotations can be used to control Pod logs collection:

*   `k8s.grafana.com/logs.job`: The value to use for the `job` label.
