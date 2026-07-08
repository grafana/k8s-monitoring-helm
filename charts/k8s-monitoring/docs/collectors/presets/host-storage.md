<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# host-storage.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"mounts":{"extra":[{"mountPath":"/var/lib/alloy","name":"alloy-storage","readOnly":false}]},"storagePath":"/var/lib/alloy"}` | Persists Alloy's storage (Write-Ahead Log, positions files, etc.) to a hostPath volume. Using a hostPath for a DaemonSet avoids the issues that come with PersistentVolumeClaim management. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller.volumes.extra[0].hostPath.path | string | `"/var/lib/alloy"` |  |
| controller.volumes.extra[0].hostPath.type | string | `"DirectoryOrCreate"` |  |
| controller.volumes.extra[0].name | string | `"alloy-storage"` |  |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Host Storage preset

# -- Persists Alloy's storage (Write-Ahead Log, positions files, etc.) to a hostPath volume. Using a hostPath for a
# DaemonSet avoids the issues that come with PersistentVolumeClaim management.
# @section -- Alloy Configuration
alloy:
  storagePath: /var/lib/alloy
  mounts:
    extra:
      - name: alloy-storage
        mountPath: /var/lib/alloy
        readOnly: false

controller:
  volumes:
    extra:
      - name: alloy-storage
        hostPath:
          path: /var/lib/alloy
          type: DirectoryOrCreate
```
<!-- textlint-enable terminology -->
