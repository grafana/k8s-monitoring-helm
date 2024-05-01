# Default Allow Lists

Most metric sources have the ability to adjust the amount of metrics being scraped and their labels. This can be useful to
limit the number of metrics. Many of the metric sources have an allow list, which is a set of metric names that
will be kept, while any metrics not on the list will be dropped. The allow lists are tuned to return a useful, but
minimal set of metrics for Kubernetes Monitoring.

If you want to allow all metrics, set this in the values file:

```yaml
metrics:
  <metric source>:
    metricsTuning:
      useDefaultAllowList: false
```

| Metric Source      | Allow List                                                         | Purpose                   |
|--------------------|--------------------------------------------------------------------|---------------------------|
| Alloy              | [alloy.yaml](./alloy.yaml)                                         | Return Alloy version      |
| Alloy              | [alloy_integration.yaml](/alloy_integration.yaml)                  | Capture Alloy behavior    |
| cAdvisor           | [cadvisor.yaml](./cadvisor.yaml)                                   | Container metrics         |
| kube-state-metrics | [kube_state_metrics.yaml](./kube_state_metrics.yaml)               | Cluster objects           |
| Kubelet            | [kubelet.yaml](./kubelet.yaml)                                     | Cluster metrics           |
| Node Exporter      | [node_exporter.yaml](./node_exporter.yaml)                         | Basic Node health         |
| Node Exporter      | [node_exporter_integration.yaml](./node_exporter_integration.yaml) | Detailed Node health      |
| OpenCost           | [opencost.yaml](./opencost.yaml)                                   | Cluster cost metrics      |
| Windows Exporter   | [windows_exporter.yaml](./windows_exporter.yaml)                   | Basic Windows Node health |
