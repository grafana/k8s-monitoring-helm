<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Resource requests and limits

This example demonstrates how to set resource requests and limits for every Kubernetes deployment available from this
Helm chart. Resource requests ensure that the container has the necessary resources to run, while limits prevent it from
consuming too many resources. These settings are often not set by default, because the "correct" values depend on the
size and complexity of the cluster, the number of workloads and their activity, and many more factors.

For Alloy, there are [best practices](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) for
setting these values, based on the purpose of that Alloy instance and the amount of data it is expected to handle.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: resources-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  kube-state-metrics:
    resources:
      requests:
        cpu: 10m
        memory: 32Mi
      limits:
        cpu: 100m
        memory: 64Mi

  node-exporter:
    resources:
      limits:
        cpu: 200m
        memory: 50Mi
      requests:
        cpu: 100m
        memory: 30Mi

  windows-exporter:
    resources:
      limits:
        cpu: 200m
        memory: 50Mi
      requests:
        cpu: 100m
        memory: 30Mi

  opencost:
    exporter:
      resources:
        requests:
          cpu: 10m      # The default set in the OpenCost Helm chart
          memory: 55Mi  # The default set in the OpenCost Helm chart
        limits:
          cpu: 100m
          memory: 1Gi  # The default set in the OpenCost Helm chart

  kepler:
    enabled: true
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi

autoInstrumentation:
  enabled: true
  beyla:
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
      requests:
        cpu: 100m
        memory: 128Mi

alloy-metrics:
  enabled: true
  alloy:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
  configReloader:
    resources:
      requests:
        cpu: 10m      # The default set in the Alloy Helm chart
        memory: 50Mi  # The default set in the Alloy Helm chart
      limits:
        cpu: 100m
        memory: 128Mi

alloy-operator:
  resources:
    requests:
      cpu: 10m
      memory: 64Mi
    limits:
      cpu: 500m
      memory: 128Mi
```
<!-- textlint-enable terminology -->
