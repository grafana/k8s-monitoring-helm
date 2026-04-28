<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Prometheus Destination with PrometheusRule Sync

A `prometheus`-type destination can opt into synchronizing
[`PrometheusRule`](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api-reference/api.md#prometheusrule)
objects with its Ruler API. When `rules.enabled` is `true` on a destination, the chart configures Alloy's
[`mimir.rules.kubernetes`](https://grafana.com/docs/alloy/latest/reference/components/mimir/mimir.rules.kubernetes/)
component on the chosen collector. Discovered recording and alerting rules are pushed to the destination's
Mimir/Cortex/Prometheus-compatible Ruler, reusing the destination's existing URL, tenant ID, and authentication
settings.

`rules.collector` selects which collector hosts the synchronization loop — exactly one collector should own this so
multiple Alloy replicas don't race when writing to the Ruler API.

`rules.address` is the base URL of the Ruler API. Set it when `url` is the remote-write push URL (for example,
Grafana Cloud's `/api/prom/push` endpoint), since `mimir.rules.kubernetes` expects the Mimir base URL rather than
the push path.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: prom-rules-cluster

destinations:
  mimir:
    type: prometheus
    url: http://mimir.mimir.svc:9009/api/v1/push
    rules:
      enabled: true
      address: http://mimir.mimir.svc:9009/
      collector: alloy-singleton
      syncInterval: 15s
      mimirNamespacePrefix: integration-test

# selfReporting is on by default and pushes `grafana_kubernetes_monitoring_build_info`,
# which feeds the recording rules so they have data to evaluate against.

collectors:
  alloy:
    enabled: true
```
<!-- textlint-enable terminology -->
