<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Remote Config

This example demonstrates how to configure Alloy to utilize
[remote configuration](https://grafana.com/docs/alloy/latest/reference/config-blocks/remotecfg/).

## Values

```yaml
---
cluster:
  name: remote-config-example-cluster

alloy-metrics:
  enabled: true
  alloy:
    stabilityLevel: public-preview
  remoteConfig:
    enabled: true
    url: "https://remote-config.example.com/alloy"
    auth:
      type: "basic"
      username: "my-remote-cfg-user"
      password: "my-remote-cfg-password"
```
