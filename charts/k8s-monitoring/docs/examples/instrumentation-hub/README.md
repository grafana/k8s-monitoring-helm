<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: instrumentation-hub/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: instrumentation-hub-test-cluster

telemetryServices:
  node-exporter:
    deploy: true

  kube-state-metrics:
    deploy: true

collectorCommon:
  alloy:
    remoteConfig:
      enabled: true
      url: https://remote-config.example.com/alloy
      auth:
        type: basic
        username: 12345
        password: my-remote-cfg-password

collectors:
  my-collector:
    presets: [daemonset]
```
<!-- textlint-enable terminology -->
