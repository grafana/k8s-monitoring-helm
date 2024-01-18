# Custom Metrics Tuning

This example shows some options for metric tuning to allow greater or fewer metrics to be sent to Prometheus.

In the example values file, here are the various settings and their effect:

| Default Allow List | includeMetrics | excludeMetrics   | Result                                                                           |
|--------------------|----------------|------------------|----------------------------------------------------------------------------------|
| false              | `[]`           | `[]`             | No filter, keep all metrics                                                      |
| true               | `[]`           | `[]`             | Use the default metric filter                                                    |
| true               | `[my_metric]`  | `[]`             | Use the default metric filter with an additional metric                          |
| true               | `[]`           | `[my_metric_.*]` | Use the default metric filter, but excluding anything starting with `my_metric_` |
| false              | `[my_metric]`  | `[]`             | *Only* keep `my_metric`                                                          |
| false              | `[]`           | `[my_metric_.*]` | Keep all metrics except anything starting with `my_metric_`                      |

```yaml
cluster:
  name: custom-allow-lists-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"

metrics:
  agent:
    metricsTuning:  # Will filter to the metrics that will populate the Grafana Agent integration: https://grafana.com/docs/grafana-cloud/monitor-infrastructure/integrations/integration-reference/integration-grafana-agent/
      useIntegrationAllowList: true
  kube-state-metrics:
    metricsTuning:  # No filtering, keep all metrics
      useAllowList: false
  node-exporter:
    metricsTuning:  # Will filter to the metrics that will populate the Linux node integration: https://grafana.com/docs/grafana-cloud/monitor-infrastructure/integrations/integration-reference/integration-linux-node/
      useIntegrationAllowList: true
  kubelet:
    metricsTuning:  # Will only keep these two metrics
      useAllowList: false
      includeMetrics: ["kubelet_node_name","kubernetes_build_info"]
  cadvisor:
    metricsTuning:  # Will keep the default set of metrics and also include these three more
      useAllowList: true
      includeMetrics:
        - container_memory_cache
        - container_memory_rss
        - container_memory_swap
  cost:
    metricsTuning:  # Will keep all metrics except those that start with "go_*"
      useAllowList: false
      excludeMetrics: ["go_*"]
  enabled: true

logs:
  pod_logs:
    enabled: false

  cluster_events:
    enabled: false
```