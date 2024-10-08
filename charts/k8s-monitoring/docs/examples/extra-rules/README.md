<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Extra Rules

This example shows several ways to provide additional labels and rules. Most metric sources include fields for:

*   `extraDiscoveryRules` - Rules that control service discovery, as well as setting labels from the discovered targets.
*   `extraMetricProcessingRules` - Rules that control metric processing, such as modifying labels or filtering metrics.
*   `metricsTuning` - More controls for keeping or dropping metrics. See [this example](../metrics-tuning) for more details.

Most logs sources include fields for:

*   `extraDiscoveryRules` - Rules that control service discovery, as well as setting labels from the discovered targets.
*   `extraLogProcessingStages` - Rules that control log processing, such as modifying labels or modifying content.

## Values

```yaml
---
cluster:
  name: extra-rules-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
    extraLabels:
      site: lab2
    extraLabelsFrom:
      region: env("REGION")
    metricProcessingRules: |-
      write_relabel_config {
        source_labels = ["__name__"]
        regex = "metric_to_drop|another_metric_to_drop"
        action = "drop"
      }

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    extraLabels:
      site: lab2
    extraLabelsFrom:
      region: env("REGION")

clusterMetrics:
  enabled: true
  kube-state-metrics:
    extraMetricRelabelingRules: |-
      rule {
        source_labels = ["namespace"]
        regex = "production"
        action = "keep"
      }

clusterEvents:
  enabled: true
  namespaces:
    - production
  extraProcessingStages: |-
    stage.logfmt {
      payload = ""
    }

    stage.json {
      source = "payload"
      expressions = {
        sku = "id",
        count = "",
      }
    }

    stage.static {
      values = {
        site = "lab2",
      }
    }

    stage.labels {
      values = {
        sku  = "",
        count = "",
      }
    }

podLogs:
  enabled: true
  extraDiscoveryRules: |-
    rule {
      source_labels = ["__meta_kubernetes_namespace"]
      regex = "production"
      action = "keep"
    }

  extraLogProcessingStages: |-
    stage.json {
      source = "payload"
      expressions = {
        sku = "id",
        count = "",
      }
    }

    stage.static {
      values = {
        site = "lab2",
      }
    }

    stage.labels {
      values = {
        sku  = "",
        count = "",
      }
    }

alloy-metrics:
  enabled: true
  alloy:
    extraEnv:
      - name: REGION
        value: northwest

alloy-singleton:
  enabled: true
  alloy:
    extraEnv:
      - name: REGION
        value: northwest

alloy-logs:
  enabled: true
  alloy:
    extraEnv:
      - name: REGION
        value: northwest
```
