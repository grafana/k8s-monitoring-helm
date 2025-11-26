<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Node Logs

This example demonstrates how to gather logs from the Nodes in your Kubernetes cluster. It currently gathers logs from
the journald services on the node and requires a HostPath volume mount to `/var/log/journal`.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: kubernetes-manifest-cluster

destinations:
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

kubernetesManifests:
  enabled: true
  namespaces: [default]  # Comment out for all namespaces
  kinds:
    pods:
      gather: true
    deployments:
      gather: false
    statefulsets:
      gather: false
    daemonsets:
      gather: false
    cronjobs:
      gather: false

alloy-singleton:
  enabled: true
  alloy:
    stabilityLevel: public-preview
```
<!-- textlint-enable terminology -->
