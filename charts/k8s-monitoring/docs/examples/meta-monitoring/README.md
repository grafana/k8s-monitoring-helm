<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: meta-monitoring/values.yaml

## Values

<!-- textlint-disable terminology -->
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
  - name: tempo
    type: otlp
    protocol: http
    url: http://tempo.tempo.svc:443/otlp
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

integrations:
  collector: alloy-singleton
  # attach available node labels to all integration metrics collection
  nodeLabels:
    nodepool: true
    region: true
    availability_zone: true
    node_role: true
    os: true
    architecture: true
    instance_type: true

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
    - collectors
    - logs
    - metrics
    - o11y

clusterMetrics:
  enabled: true
  collector: alloy-singleton
  nodeLabels:
    nodePool: true
    region: true
    availabilityZone: true
    nodeRole: true
    os: true
    architecture: true
    instanceType: true

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
        regex = "collectors|logs|metrics|o11y"
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
    namespaces: collectors,logs,metrics,o11y
    metricsTuning:
      useDefaultAllowList: false
      includeMetrics: [(.+)]
  node-exporter:
    enabled: true
    deploy: true
    metricsTuning:
      useIntegrationAllowList: true
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
  collector: alloy-singleton
  nodeLabels:
    nodePool: true
    region: true
    availabilityZone: true
    nodeRole: true
    os: true
    architecture: true
    instanceType: true

  structuredMetadata:
    nodepool:
    region:
    availability_zone:
    node_role:
    os:
    architecture:
    instance_type:

  labelsToKeep:
    - app
    - app_kubernetes_io_name
    - component
    - container
    - job
    - level
    - namespace
    - pod
    - service_name

  gatherMethod: kubernetesApi
  namespaces:
    - collectors
    - logs
    - metrics
    - o11y

applicationObservability:
  enabled: true
  receivers:
    jaeger:
      thriftHttp:
        enabled: true
        port: 14268
  processors:
    k8sattributes:
      metadata:
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.deployment.name
        - k8s.statefulset.name
        - k8s.daemonset.name
        - k8s.cronjob.name
        - k8s.job.name
        - k8s.node.name
        - k8s.pod.uid
        - k8s.pod.start_time
        - k8s.container.name

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
  enabled: true
  alloy:
    extraPorts:
      - name: jaeger-http
        port: 14268
        targetPort: 14268
        protocol: TCP
```
<!-- textlint-enable terminology -->
