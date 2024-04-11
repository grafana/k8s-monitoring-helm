# Helm tests

This Helm chart contains a number of tests to ensure that things are working correctly. This document explains them and
describes how you can interact and modify them.

## Pre-install, pre-upgrade validation

Before every install or upgrade, the chart deploys a Pod with the Grafana Agent and a ConfigMap with the generated
configurations. The Pod inspects the configuration files, and validates their syntax and some internal structure. If the
configuration is found to be invalid, the install or upgrade is stopped.

Change the settings for this validation in the `configValidator` section of the values file.

## Data test

This test is useful for validating that the complete end-to-end journey for the data is successful. When `helm test` is
run, a Job is created that can send queries to the various data sources to ensure that expected data has been delivered.
Some queries are built-in, and you can add others in the `test.extraQueries` section.

Note that in order for this to work, the credentials for each data source needs the ability to query data. For example,
if sending data to Grafana Cloud, some
[Access Policy Tokens](https://grafana.com/docs/grafana-cloud/account-management/authentication-and-permissions/access-policies/)
do not contain the `<dataType>:read` scope for reading data from the data source. You must either grant that

### Default queries

These queries are added by default and are used if their respective metric source is enabled:

| Metric Source             | Query                                                                       | Condition                                                                |
|---------------------------|-----------------------------------------------------------------------------|--------------------------------------------------------------------------|
|                           | `up`                                                                        | `metrics.enabled: true`                                                  |
| Grafana Agent             | `agent_build_info{cluster="<clusterName>"}`                                 | `metrics.enabled: true`<br>`metrics.agent.enabled: true`                 |
| Kubelet                   | `kubernetes_build_info{cluster="<clusterName>"}`                            | `metrics.enabled: true`<br>`metrics.kubelet.enabled: true`               |
| cAdvisor                  | `machine_memory_bytes{cluster="<clusterName>"}`                             | `metrics.enabled: true`<br>`metrics.cadvisor.enabled: true`              |
| kube-state-metrics        | `kube_node_info{cluster="<clusterName>"}`                                   | `metrics.enabled: true`<br>`metrics.kube-state-metrics.enabled: true`    |
| Node Exporter             | `node_exporter_build_info{cluster="<clusterName>"}`                         | `metrics.enabled: true`<br>`metrics.node-exporter.enabled: true`         |
| Windows Exporter          | `windows_exporter_build_info{cluster="<clusterName>"}`                      | `metrics.enabled: true`<br>`metrics.windows-exporter.enabled: true`      |
| API Server                | `apiserver_request_total{cluster="<clusterName>"}`                          | `metrics.enabled: true`<br>`metrics.apiserver.enabled: true`             |
| Kube Controller Manager   | `workqueue_adds_total{cluster="<clusterName>"}`                             | `metrics.enabled: true`<br>`metrics.kubeControllerManager.enabled: true` |
| Kube Proxy                | `kubeproxy_sync_proxy_rules_service_changes_total{cluster="<clusterName>"}` | `metrics.enabled: true`<br>`metrics.kubeProxy.enabled: true`             |
| Kube Scheduler            | `scheduler_unschedulable_pods{cluster="<clusterName>"}`                     | `metrics.enabled: true`<br>`metrics.kubeScheduler.enabled: true`         |
| OpenCost                  | `opencost_build_info{cluster="<clusterName>"}`                              | `metrics.enabled: true`<br>`metrics.cost.enabled: true`                  |
| Helm Chart self-reporting | `grafana_kubernetes_monitoring_build_info{cluster="<clusterName>"}`         | `metrics.enabled: true`<br>`metrics.kubernetesMonitoring.enabled: true`  |

#### Extra Queries

You can add additonal queries using the `test.extraQueries` section. An extra query can have this format:

```yaml
query: "<query string>",
type: "[promql (default)|logql|traceql]|[pyroql]",
```

For PromQL queries, you can add an "expect" section to the query to validate the returned value:

```yaml
  expect:
    operator": "[<, <=, ==, !=, =>, >]"
    value": <expected value>
}
```

#### Examples

Here is an example that validates that the number of nodes detected matches the expected number of nodes in the Cluster.

```yaml
- query: count(kube_node_info{cluster="my-cluster"})
  type: promql
  expect:
    value: 2
```

This query will ensure that the DPM is exactly 1, meaning only one data point per minute. This is useful for ensuring
that metric sources are not being duplicated or double-scraped:

```yaml
- query: avg(count_over_time(scrape_samples_scraped{cluster="my-cluster"}[1m]))
  type: promql
  expect:
    value: 1
    operator: ==
```

## Configuration analysis

Also when `helm test` is run, a Pod is created that builds a report of how the configuration is performing on the
Cluster. For example, for all of the `discovery.relabel` components, how many objects were input and how many remain
after the rules were applied? For `prometheus.scrape` components, was the scrape successful? This report can be helpful
for diagnosing missing or duplicate metrics, because it will show if a relabel filter is removing the desired object, or
if the metrics scrape failed.

Here is the report of the `discovery.relabel` component that filters from all Services to just the one for
kube-state-metrics:

```text
discovery.relabel.kube_state_metrics
  Inputs: discovery.kubernetes.services (61)
  Outputs: prometheus.scrape.kube_state_metrics (1)
```

Here is the report for the `prometheus.scrape` component that scrapes metrics from the discovered `kube-state-metrics`
service:

```text
prometheus.scrape.kube_state_metrics
  Inputs: 1
  - k8s-monitoring-5sdguz5u4l-kube-state-metrics.monitoring.svc:8080
  Scrapes: 1
  - URL: http://k8s-monitoring-5sdguz5u4l-kube-state-metrics.monitoring.svc:8080/metrics
    Health: up
    Last scrape: 2024-04-05T13:50:37.761494213Z (19.154181ms)
```

It also works with Prometheus Operator objects, where discovery and scraping are combined into a single component:

```text
prometheus.operator.servicemonitors.service_monitors
  Discovered: 1
  - ServiceMonitor: loki/loki
  Scrapes: 1
  - URL: http://10.244.1.14:3100/metrics
    Health: up
    Last scrape: 2024-04-05T13:50:47.107628637Z (13.38663ms)
```

## Deprecation checks

Internally, the Helm chart checks for deprecated values and provides a suggestion for resolution. The list of
deprecations can be found in the [main README](../README.md).
