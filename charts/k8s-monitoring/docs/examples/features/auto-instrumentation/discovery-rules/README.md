<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Zero-code nstrumentation with Discovery Rules

This example demonstrates how to enable the zero-code instrumentation feature, which deploys Grafana Beyla to automatically
instrument your application for metrics collection. It also shows how to set
[discovery rules](https://grafana.com/docs/beyla/latest/configure/service-discovery/) to control which services are
instrumented.

In this example, Beyla is configured with two discovery rules:

*   Do not instrument anything in the `kube-system` namespace.
*   Instrument anything with the Pod label `instrument=beyla`

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: auto-instrumentation-with-rules-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

autoInstrumentation:
  enabled: true
  spanMetricsOnly: true
  beyla:
    config:
      data:
        discovery:
          exclude_services:
            - k8s_namespace: kube-system
          services:
            - k8s_pod_labels:
                instrument: beyla

alloy-metrics:
  enabled: true
```
<!-- textlint-enable terminology -->
