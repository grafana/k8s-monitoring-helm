# Targeted data collection

The Kubernetes Monitoring Helm chart allows you to target specific namespaces or Pods for data collection. There are
many different methods to control this, and the following sections will explain how to use many of them.

## Kubernetes Annotations

Often annotations are used for controlling service discovery, but you can also use them to configure how data is
collected. Several features within this Helm chart can be controlled using Kubernetes annotations.

### Feature: Annotation Autodiscovery

Use the [Annotation Autodiscovery feature](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-annotation-autodiscovery) to discover and scrape Prometheus-style metrics from Pods and Services
on your Cluster. You can apply these default annotations to a Pod or Service:

*   `k8s.grafana.com/scrape`: Scrape this Pod or Service for metrics.
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

### Feature: Profiling

The [Profiling feature](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-profiling) allows you to collect profiling data from your applications. This feature can collect
profiles using eBPF, Java, or pprof.

#### eBPF Profiling

`profiles.grafana.com/cpu.ebpf.enabled`: Using eBPF, collect CPU profiles from this Pod.

#### Java Profiling

`profiles.grafana.com/java.enabled`: Collect Java profiles from this Pod.

#### pprof Profiling

For each enabled type (`memory`, `block`, `goroutine`, `mutex`, `cpu`, `fgprof`, `godeltaprof_memory`,
`godeltaprof_mutex`, `godeltaprof_block`), you can use the following annotations to control profiling:

*   `profiles.grafana.com/<type>.scrape`: This Pod should have pprof profiles collected for the specified type.
*   `profiles.grafana.com/<type>.port`: Profiles for the specified type should be collected from this port number.
*   `profiles.grafana.com/<type>.port_name`: Profiles for the specified type should be collected from this named port.
*   `profiles.grafana.com/<type>.path`: Profiles for the specified type should be collected from this path.
*   `profiles.grafana.com/<type>.scheme`: The scheme to use when scraping profiles for the specified type. Defaults to `http`.

### Feature: Pod Logs

Use the following annotation to control [Pod logs](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-pod-logs) collection:

`k8s.grafana.com/logs.job`: The value to use for the `job` label.
