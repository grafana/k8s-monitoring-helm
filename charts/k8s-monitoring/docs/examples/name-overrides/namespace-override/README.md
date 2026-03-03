<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Namespace Override

This example shows how to set `global.namespaceOverride` so namespaced resources are
created in a custom namespace instead of the Helm release namespace.

This is useful when `k8s-monitoring` is installed as a subchart and should deploy into
a shared observability namespace.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: namespace-override-test

global:
  namespaceOverride: observability

destinations:
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push

podLogs:
  enabled: true

alloy-logs:
  enabled: true
```
<!-- textlint-enable terminology -->
