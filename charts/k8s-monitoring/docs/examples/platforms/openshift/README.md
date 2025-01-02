<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# OpenShift

This example shows the modifications requires to deploy to an OpenShift cluster.

These modifications skip the deployment of kube-state-metrics and Node Exporter, since they will already be present on
the cluster, and adjust the configuration to Grafana Alloy to find those existing components.
It also modifies Grafana Alloy to lock down security and permissions.

The `platform: openshift` switch also creates SecurityContextConstraints objects that modifies the permissions for the
Grafana Alloy.

Note that these alloy pods cannot enable `readOnlyRootFilesystem` because they require being able to write to their
storage path, which defaults to `/tmp/alloy`.

## Values

```yaml
---
cluster:
  name: openshift-cluster

global:
  platform: openshift

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  - name: loki
    type: loki
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  kepler:
    enabled: true

clusterEvents:
  enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true

alloy-singleton:
  enabled: true

alloy-logs:
  enabled: true
```
