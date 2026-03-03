<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Namespace Override

This example shows how to set `global.namespaceOverride` so namespaced resources are created in a custom namespace
instead of the Helm release namespace. This is useful when this Helm chart must be deployed to a namespace, but you want
the artifacts deployed to a different namespace.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: namespace-override-test

global:
  namespaceOverride: observability

destinations:
  loki:
    type: loki
    url: http://loki.loki.svc:3100/api/push

podLogsViaLoki:
  enabled: true

collectors:
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
```
<!-- textlint-enable terminology -->
