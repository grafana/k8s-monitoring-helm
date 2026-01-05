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
  name: node-logs-cluster

destinations:
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

nodeLogs:
  enabled: true
  journal:
    units:
      - kubelet.service
      - containerd.service

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
