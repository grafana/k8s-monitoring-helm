# Custom Metrics Tuning

This example shows some options for metric tuning to allow greater or fewer metrics to be sent to Prometheus.

In the example values file, here are the various settings and their effect:

| Default Allow List | includeMetrics   | excludeMetrics           | Result                                                                                                                         |
|--------------------|------------------|--------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| true               | `[]`             | `[]`                     | Use the default metric filter                                                                                                  |
| false              | `[]`             | `[]`                     | No filter, keep all metrics                                                                                                    |
| true               | `[my_metric]`    | `[]`                     | Use the default metric filter with an additional metric                                                                        |
| false              | `[my_metric_.*]` | `[]`                     | *Only* keep metrics that start with `my_metric_`                                                                               |
| true               | `[]`             | `[my_metric_.*]`         | Use the default metric filter, but excluding anything starting with `my_metric_`                                               |
| false              | `[]`             | `[my_metric_.*]`         | Keep all metrics except anything starting with `my_metric_`                                                                    |
| true               | `[my_metric_.*]` | `[other_metric_.*]`      | Use the default metric filter, and keep anything starting with `my_metric_`, but remove anything starting with `other_metric_` |
| false              | `[my_metric_.*]` | `[my_metric_not_needed]` | *Only* keep metrics that start with `my_metric_`, but remove any that are named `my_metric_not_needed`                         |

<!-- values file start -->
```yaml
---
cluster:
  name: custom-allow-lists-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"

metrics:
  # Will filter to the metrics that will populate the Grafana Alloy integration
  alloy:
    metricsTuning:
      useIntegrationAllowList: true

  # No filtering, keep all metrics from kube-state-metrics
  kube-state-metrics:
    metricsTuning:
      useDefaultAllowList: false

  # Will filter the Node Exporter metrics that will populate the Linux node integration
  # See https://grafana.com/docs/grafana-cloud/monitor-infrastructure/integrations/integration-reference/integration-linux-node/
  node-exporter:
    metricsTuning:
      useIntegrationAllowList: true

  # Will only keep these two kubelet metrics
  kubelet:
    metricsTuning:
      useDefaultAllowList: false
      includeMetrics:
        - kubelet_node_name
        - kubernetes_build_info

  # Will keep the default set of cAdvisor metrics and also include these three more
  cadvisor:
    metricsTuning:
      useDefaultAllowList: true
      includeMetrics:
        - container_memory_cache
        - container_memory_rss
        - container_memory_swap

  # Will keep all cost metrics except those that start with "go_*"
  cost:
    metricsTuning:
      useDefaultAllowList: false
      excludeMetrics: ["go_*"]
  enabled: true

logs:
  enabled: false
  pod_logs:
    enabled: false

  cluster_events:
    enabled: false
```
<!-- values file end -->
