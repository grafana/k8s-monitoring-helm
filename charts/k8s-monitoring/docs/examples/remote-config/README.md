<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Remote Config

This example demonstrates how to configure Alloy to utilize
[remote configuration](https://grafana.com/docs/alloy/latest/reference/config-blocks/remotecfg/).

By default, the chart generates a collector ID for each Alloy instance:

*   For Deployments and StatefulSets: `<release name>-<cluster name>-<namespace>-<collector name>`
*   For DaemonSets: `<release name>-<cluster name>-<namespace>-<collector name>-<node name>`

You can override the collector ID with `remoteConfig.collectorId` or `remoteConfig.collectorIdFrom`. For example, to
load the collector ID from an environment variable, set `collectorIdFrom: sys.env("GCLOUD_FM_COLLECTOR_ID")`.

`GCLOUD_RW_API_KEY` must also be set. It should be a Grafana Cloud Access Policy token that has the following scopes:

*   `fleet-management:read`
*   `logs:write`
*   `metrics:write`
*   `traces:write`
*   `profiles:write`

The values file below shows enabling remote configuration for the `alloy-metrics` StatefulSet and the `alloy-logs`
DaemonSet.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: remote-config-example-cluster

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
  alloy-metrics:
    presets: [clustered, statefulset]

  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
```
<!-- textlint-enable terminology -->
