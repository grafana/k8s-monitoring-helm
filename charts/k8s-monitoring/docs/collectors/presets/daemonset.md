<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# daemonset.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"tolerations":[{"effect":"NoSchedule","operator":"Exists"}],"type":"daemonset"}` | Configures Alloy to run as a DaemonSet, ensuring a single instance per node. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# DaemonSet preset

# -- Configures Alloy to run as a DaemonSet, ensuring a single instance per node.
# @section -- Alloy Configuration
controller:
  type: daemonset
  tolerations:
    - effect: NoSchedule
      operator: Exists
```
<!-- textlint-enable terminology -->
