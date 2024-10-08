<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Metrics Tuning

This example shows some options for metric tuning to allow greater or fewer metrics to be sent to a metrics destination.

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

## Values

```yaml
---
cluster:
  name: metrics-tuning-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

annotationAutodiscovery:
  enabled: true
  metricsTuning:
    excludeMetrics: ["go_*"]

clusterMetrics:
  enabled: true
  kube-state-metrics:
    metricsTuning:
      # No filtering, keep all metrics
      useDefaultAllowList: false
  node-exporter:
    metricsTuning:
      # Will filter to the metrics that will populate the Linux node integration
      # See https://grafana.com/docs/grafana-cloud/monitor-infrastructure/integrations/integration-reference/integration-linux-node/
      useIntegrationAllowList: true
  kubelet:
    metricsTuning:
      # Will only keep these two metrics
      useDefaultAllowList: false
      includeMetrics:
        - kubelet_node_name
        - kubernetes_build_info
  cadvisor:
    metricsTuning:
      # Will keep the default set of metrics and also include these three more
      useDefaultAllowList: true
      includeMetrics:
        - container_memory_cache
        - container_memory_rss
        - container_memory_swap

alloy-metrics:
  enabled: true
```
