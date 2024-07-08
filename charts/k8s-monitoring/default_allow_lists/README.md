# Default Allow Lists

Most metric sources have the ability to adjust the amount of metrics being scraped and their labels. This can be useful
to
limit the number of metrics. Many of the metric sources have an allow list, which is a set of metric names that
will be kept, while any metrics not on the list will be dropped. The allow lists are tuned to return a useful, but
minimal set of metrics for [Kubernetes Monitoring](https://grafana.com/solutions/kubernetes/).

You can control the use of these allow lists by using these fields in the values file:

```yaml
metrics:
  <metric source>:
    metricsTuning:
      useDefaultAllowList: <boolean>
      useIntegrationAllowList: <boolean>
```

The `metricsTuning` section also offers more fine-grained control of the allowed metrics, including or excluding metrics
by name or by regular expression. You can learn more in [this example](../../../examples/custom-metrics-tuning).

You can also use the `extraMetricRelabelingRules` section to add arbitrary relabeling rules that can be used to take any
action on the metric list, including filtering based on label or other actions.

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
