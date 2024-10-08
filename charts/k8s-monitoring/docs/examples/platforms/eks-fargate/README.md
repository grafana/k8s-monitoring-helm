<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# EKS Fargate

AWS EKS Fargate Kubernetes clusters have a fully managed control plane, which reduce the management needs of the user,
but need extra consideration because they often have restrictions around DaemonSets and node access. This prevents
services like Node Exporter from working properly. It also has implications for how Pod logs are gathered, since the
typical method is to deploy Grafana Alloy as a Daemonset with HostPath volume mounts to gather the log files.
Consequently, Alloy must be deployed to use the
[Kubernetes API log gathering](https://grafana.com/docs/alloy/latest/reference/components/loki.source.kubernetes/)
method instead.

Missing Node Exporter metrics is likely fine, because users of these clusters should not need concern themselves with
the health of the nodes. That's the responsibility of the cloud provider.

This example shows how to disable Node Exporter and gather Pod logs via the Kubernetes API:

## Values

```yaml
---
cluster:
  name: eks-fargate-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

clusterMetrics:
  enabled: true
  node-exporter:
    deploy: false
    enabled: false

clusterEvents:
  enabled: true

podLogs:
  enabled: true
  gatherMethod: kubernetesApi

alloy-metrics:
  enabled: true
alloy-singleton:
  enabled: true
alloy-logs:
  enabled: true
  alloy:
    clustering:
      enabled: true
    mounts:
      varlog: false
  controller:
    replicas: 2
    type: deployment
```
