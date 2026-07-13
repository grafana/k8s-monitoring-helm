<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# host-tracefs.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"mounts":{"extra":[{"mountPath":"/sys/kernel/tracing","name":"tracefs"}]}}` | Mounts the host's tracing filesystem into Alloy, allowing it to attach eBPF tracepoints. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller.volumes.extra[0].hostPath.path | string | `"/sys/kernel/tracing"` |  |
| controller.volumes.extra[0].hostPath.type | string | `"Directory"` |  |
| controller.volumes.extra[0].name | string | `"tracefs"` |  |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Host Tracefs preset

# -- Mounts the host's tracing filesystem into Alloy, allowing it to attach eBPF tracepoints.
# @section -- Alloy Configuration
alloy:
  mounts:
    extra:
      - name: tracefs
        mountPath: /sys/kernel/tracing

controller:
  volumes:
    extra:
      - name: tracefs
        hostPath:
          path: /sys/kernel/tracing
          type: Directory
```
<!-- textlint-enable terminology -->
