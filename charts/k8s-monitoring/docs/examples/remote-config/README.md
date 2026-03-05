<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Remote Config

This example demonstrates how to configure Alloy to utilize
[remote configuration](https://grafana.com/docs/alloy/latest/reference/config-blocks/remotecfg/). These two environment
variables must be set:

*   `GCLOUD_FM_COLLECTOR_ID` - The collector id. It should uniquely identify this Alloy instance. The value in practice is:
    *   For Deployments: `<cluster name>-<namespace>-<pod name>`
    *   For StatefulSets: `<cluster name>-<namespace>-<pod name>`
    *   For DaemonSets: `<cluster name>-<namespace>-<node name>`
*   `GCLOUD_RW_API_KEY` - The Grafana Cloud Access Policy token that has the following scopes:
    *   `fleet-management:read`
    *   `logs:write`
    *   `metrics:write`
    *   `traces:write`
    *   `profiles:write`

The values file below shows enabling the `alloy-metrics` StatefulSet and the `alloy-logs` DaemonSets and a convenient
way to set the environment variables automatically.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: remote-config-example-cluster

alloy-metrics:
  enabled: true
  remoteConfig:
    enabled: true
    url: https://remote-config.example.com/alloy
    auth:
      type: basic
      username: 12345
      password: my-remote-cfg-password
  alloy:
    extraEnv:
      - name: GCLOUD_RW_API_KEY
        valueFrom:
          secretKeyRef:
            name: alloy-metrics-remote-cfg-k8smon-k8s-monitoring
            key: password
      - name: CLUSTER_NAME
        value: remote-config-example-cluster
      - name: NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace
      - name: POD_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.name
      - name: GCLOUD_FM_COLLECTOR_ID
        value: k8smon-$(CLUSTER_NAME)-$(NAMESPACE)-$(POD_NAME)

alloy-logs:
  enabled: true
  remoteConfig:
    enabled: true
    url: https://remote-config.example.com/alloy
    auth:
      type: basic
      username: my-remote-cfg-user
      password: my-remote-cfg-password
  alloy:
    extraEnv:
      - name: GCLOUD_RW_API_KEY
        valueFrom:
          secretKeyRef:
            name: alloy-logs-remote-cfg-k8smon-k8s-monitoring
            key: password
      - name: CLUSTER_NAME
        value: remote-config-example-cluster
      - name: NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace
      - name: NODE_NAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
      - name: GCLOUD_FM_COLLECTOR_ID
        value: k8smon-$(CLUSTER_NAME)-$(NAMESPACE)-alloy-logs-$(NODE_NAME)
```
<!-- textlint-enable terminology -->
