<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: metric-enrichment/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: metric-enrichment-test-cluster

destinations:
  - name: metric-store
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
  - name: metric-enrichment
    type: custom
    ecosystem: prometheus
    config: |
      discovery.kubernetes "metric_enrichment_pods" {
        role = "pod"
        attach_metadata {
          namespace = true
        }
      }
      discovery.relabel "metric_enrichment_pods" {
        targets = discovery.kubernetes.metric_enrichment_pods.targets
        rule {
          source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_name"]
          regex = "(.+;.+)"
          target_label = "temp_namespaced_pod"
        }
        rule {
          source_labels = ["__meta_kubernetes_namespace_label_color"]
          target_label = "color"
        }
      }
      
      prometheus.relabel "metric_enrichment" {
        rule {
          source_labels = ["namespace", "pod"]
          regex = "(.+;.+)"
          target_label = "temp_namespaced_pod"
        }
        forward_to = [prometheus.enrich.metric_enrichment.receiver]
      }
      
      prometheus.enrich "metric_enrichment" {
        targets = discovery.relabel.metric_enrichment_pods.output
        target_match_label = "temp_namespaced_pod"
        metrics_match_label = "temp_namespaced_pod"
        forward_to = [prometheus.relabel.metric_enrichment_final.receiver]
      }
      prometheus.relabel "metric_enrichment_final" {
        rule {
          action = "labeldrop"
          regex = "temp_namespaced_pod|__address__|__meta.*"
        }
        forward_to = [prometheus.remote_write.metric_store.receiver]
      }
    metrics:
      enabled: true
      target: prometheus.relabel.metric_enrichment.receiver

clusterMetrics:
  enabled: true
  destinations: [metric-enrichment]

alloy-metrics:
  enabled: true
  includeDestinations: [metric-store]
  alloy:
    stabilityLevel: experimental
```
<!-- textlint-enable terminology -->
