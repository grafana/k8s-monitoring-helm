# Extra Rules

This example shows a deployment that only gathers pod logs and Kubernetes cluster events, but no metrics.

It differs from the [default](../default-values) by not requiring a Prometheus service, disabling the deployment of metric sources (i.e. Kube State Metrics), and disabling the metrics section.

```yaml
cluster:
  name: extra-rules-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    tenantId: 2000
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"

metrics:
  extraRelabelingRules: |-
    rule {
      action = "replace"
      replacement = ""
    }
  
  kube-state-metrics:
    extraMetricRelabelingRules: |-
      rule {
        source_labels = ["namespace"]
        regex = "production"
        action = "keep"
      }

logs:
  pod_logs:
    extraRelabelingRules: |-
      rule {
        source_labels = ["__meta_kubernetes_namespace"]
        regex = "production"
        action = "keep"
      }

    extraStageBlocks: |-
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

      stage.labels {
        values = {
          sku  = "",
          count = "",
        }
      }
```
