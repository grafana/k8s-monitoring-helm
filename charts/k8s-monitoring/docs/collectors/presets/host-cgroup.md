<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# host-cgroup.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"mounts":{"extra":[{"mountPath":"/sys/fs/cgroup","name":"cgroup"}]}}` | Mounts the host's cgroup filesystem into Alloy, allowing it to read cgroup information for the node. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller.volumes.extra[0].hostPath.path | string | `"/sys/fs/cgroup"` |  |
| controller.volumes.extra[0].hostPath.type | string | `"Directory"` |  |
| controller.volumes.extra[0].name | string | `"cgroup"` |  |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Host Cgroup preset

# -- Mounts the host's cgroup filesystem into Alloy, allowing it to read cgroup information for the node.
# @section -- Alloy Configuration
alloy:
  mounts:
    extra:
      - name: cgroup
        mountPath: /sys/fs/cgroup

controller:
  volumes:
    extra:
      - name: cgroup
        hostPath:
          path: /sys/fs/cgroup
          type: Directory
```
<!-- textlint-enable terminology -->
