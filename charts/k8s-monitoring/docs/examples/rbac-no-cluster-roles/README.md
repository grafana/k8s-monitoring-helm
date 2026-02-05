<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# RBAC: No Cluster Roles

This example shows how to deploy this chart without any ClusterRoles or ClusterRoleBindings.

Without these objects, there are some things that will not function:

## Node access

Anything that requires discovering Nodes is not allowed, which means metrics from these sources will not work:

*   Kubelet
*   Kubelet Resources
*   Kubelet Probes
*   cAdvisor

kube-state-metrics will only be able to generate metrics from the namespaces that are specified. This also means that it
is unable to generate metrics for cluster-scoped resources. `kube_node_info` for example is not possible without a
ClusterRole.

## Namespace scoped

Roles and RoleBindings are only created for the namespaces that are specified in the values file. This means that the
features in this chart can only gather telemetry data from those namespaces.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: no-cluster-roles

destinations:
  - name: metric-store
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: 1
    auth:
      type: basic
      username: loki
      password: lokipassword

clusterMetrics:
  enabled: true
  # These features require listing Nodes, which require ClusterRoles, so must be disabled.
  kubelet:
    enabled: false
  kubeletResource:
    enabled: false
  kubeletProbes:
    enabled: false
  cadvisor:
    enabled: false

  kube-state-metrics:
    namespaces: default
    rbac:
      useClusterRole: false

clusterEvents:
  enabled: true
  namespaces: [default]

podLogs:
  enabled: true
  namespaces: [default]

collectorCommon:
  alloy:
    rbac:
      namespaces: [default]

alloy-metrics:
  enabled: true

alloy-singleton:
  enabled: true

alloy-logs:
  enabled: true

alloy-operator:
  ownNamespaceOnly: true
  rbac:
    createClusterRoles: false
```
<!-- textlint-enable terminology -->
