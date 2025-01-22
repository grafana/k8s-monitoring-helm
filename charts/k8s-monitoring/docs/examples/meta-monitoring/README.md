<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: meta-monitoring/values.yaml

## Values

```yaml
---
cluster:
  name: loki-meta-monitoring-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

integrations:
  collector: alloy-singleton
  alloy:
    instances:
      # monitor the collector gathering and sending meta-monitoring metrics/logs to the meta-monitoring cluster
      - name: alloy-in-logs
        namespaces:
          - logs
        labelSelectors:
          app.kubernetes.io/name: alloy-singleton

      # monitor the collectors gathering and sending metrics/logs to the local cluster
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: [alloy-singleton, alloy-metrics, alloy-logs, alloy-profiles, alloy-receiver]
        namespaces:
          - collectors

  grafana:
    instances:
      - name: grafana
        namespaces:
          - o11y
        labelSelectors:
          app.kubernetes.io/name: grafana

  loki:
    instances:
      - name: loki
        namespaces:
          - logs
        labelSelectors:
          app.kubernetes.io/name: loki
        logs:
          tuning:
            # extract logfmt fields and set them as structured metadata
            structuredMetadata:
              caller:
              tenant:
              org_id:
              user:
  mimir:
    instances:
      - name: mimir
        namespaces:
          - metrics
        labelSelectors:
          app.kubernetes.io/name: mimir
        logs:
          tuning:
            # extract logfmt fields and set them as structured metadata
            structuredMetadata:
              caller:
              tenant:
              org_id:
              user:

clusterEvents:
  enabled: true
  collector: alloy-singleton
  namespaces:
    - logs
    - metrics
    - o11y

clusterMetrics:
  enabled: true
  collector: alloy-singleton
  kubelet:
    enabled: false
  kubeletResource:
    enabled: false
  cadvisor:
    enabled: true
    extraMetricProcessingRules: |-
      rule {
        action = "keep"
        source_labels = ["namespace"]
        regex = "logs|metrics|o11y"
      }
  apiServer:
    enabled: false
  kubeControllerManager:
    enabled: false
  kubeDNS:
    enabled: false
  kubeProxy:
    enabled: false
  kubeScheduler:
    enabled: false
  kube-state-metrics:
    enabled: true
    namespaces:
      - logs
      - o11y
    extraMetricProcessingRules: |-
      rule {
        action = "keep"
        source_labels = ["namespace"]
        regex = "logs|metrics|o11y"
      }
    metricsTuning:
      useDefaultAllowList: false
      includeMetrics: [(.+)]
  node-exporter:
    enabled: true
    useIntegrationAllowList: true
    deploy: true
  windows-exporter:
    enabled: false
    deploy: false
  kepler:
    enabled: false
    deploy: false
  opencost:
    enabled: false
    deploy: false

nodeLogs:
  enabled: false

podLogs:
  enabled: true
  gatherMethod: kubernetesApi
  collector: alloy-singleton
  namespaces:
    - logs
    - metrics
    - o11y

# Collectors
alloy-singleton:
  enabled: true

alloy-metrics:
  enabled: false

alloy-logs:
  enabled: false

alloy-profiles:
  enabled: false

alloy-receiver:
  enabled: false
```
