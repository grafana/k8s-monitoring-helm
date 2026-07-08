<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# privileged.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"securityContext":{"allowPrivilegeEscalation":true,"privileged":true,"runAsGroup":0,"runAsUser":0}}` | DEPRECATED: use the `root` preset for the privileged `securityContext` and the `host-network` preset for `hostPID`. Configures Alloy to run with elevated privileges, allowing it to access system resources and perform operations that require root access. This preset cannot be combined with the `root` or `host-network` presets. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller.hostPID | bool | `true` |  |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Privileged preset

# -- DEPRECATED: use the `root` preset for the privileged `securityContext` and the `host-network` preset for
# `hostPID`. Configures Alloy to run with elevated privileges, allowing it to access system resources and perform
# operations that require root access. This preset cannot be combined with the `root` or `host-network` presets.
# @section -- Alloy Configuration
alloy:
  securityContext:
    allowPrivilegeEscalation: true
    privileged: true
    runAsGroup: 0
    runAsUser: 0

controller:
  hostPID: true
```
<!-- textlint-enable terminology -->
