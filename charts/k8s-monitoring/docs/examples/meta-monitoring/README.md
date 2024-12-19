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
      - name: alloy-singleton
        namespaces:
          - logs
      # monitor the collectors gathering and sending metrics/logs to the local cluster
      - name: alloy-metrics
        namespaces:
          - collectors
      - name: alloy-logs
        namespaces:
          - collectors
      - name: alloy-profiles
        namespaces:
          - collectors
      - name: alloy-receiver
        namespaces:
          - collectors
      - name: alloy-singleton
        namespaces:
          - collectors
  loki:
    instances:
      - name: loki
        labelSelectors:
          app.kubernetes.io/name: loki
        logs:
          enabled: true
          namespaces:
            - logs

clusterEvents:
  enabled: true
  collector: alloy-singleton
  namespaces:
    - logs

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
        regex = "logs"
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
    extraMetricProcessingRules: |-
      rule {
        action = "keep"
        source_labels = ["namespace"]
        regex = "logs"
      }
  node-exporter:
    enabled: false
    deploy: false
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
