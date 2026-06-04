<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# linux-host-monitor.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"extraEnv":[{"name":"NODE_NAME","valueFrom":{"fieldRef":{"fieldPath":"spec.nodeName"}}}],"mounts":{"extra":[{"mountPath":"/host/root","name":"host-root","readOnly":true},{"mountPath":"/host/proc","name":"host-proc","readOnly":true},{"mountPath":"/host/sys","name":"host-sys","readOnly":true}],"varlog":true},"securityContext":{"allowPrivilegeEscalation":true,"capabilities":{"add":["SYS_TIME"]},"privileged":true}}` | Grants Alloy the privileges needed to collect Linux host metrics directly using `prometheus.exporter.unix`, without requiring a separate Node Exporter deployment. It mounts the host's root, proc, and sys filesystems, runs privileged, and exposes the node name as the `NODE_NAME` environment variable. Use with `hostMetrics.linuxHosts.source: alloy` and combine with the `daemonset` preset so Alloy runs on every node, e.g. `presets: [linux-host-monitor, daemonset]`. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller.volumes.extra[0].hostPath.path | string | `"/"` |  |
| controller.volumes.extra[0].hostPath.type | string | `"Directory"` |  |
| controller.volumes.extra[0].name | string | `"host-root"` |  |
| controller.volumes.extra[1].hostPath.path | string | `"/proc"` |  |
| controller.volumes.extra[1].hostPath.type | string | `"Directory"` |  |
| controller.volumes.extra[1].name | string | `"host-proc"` |  |
| controller.volumes.extra[2].hostPath.path | string | `"/sys"` |  |
| controller.volumes.extra[2].hostPath.type | string | `"Directory"` |  |
| controller.volumes.extra[2].name | string | `"host-sys"` |  |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Linux Host Monitor preset

# -- Grants Alloy the privileges needed to collect Linux host metrics directly using `prometheus.exporter.unix`,
# without requiring a separate Node Exporter deployment. It mounts the host's root, proc, and sys filesystems, runs
# privileged, and exposes the node name as the `NODE_NAME` environment variable. Use with
# `hostMetrics.linuxHosts.source: alloy` and combine with the `daemonset` preset so Alloy runs on every node, e.g.
# `presets: [linux-host-monitor, daemonset]`.
# @section -- Alloy Configuration
alloy:
  mounts:
    varlog: true
    extra:
      - name: host-root
        mountPath: /host/root
        readOnly: true
      - name: host-proc
        mountPath: /host/proc
        readOnly: true
      - name: host-sys
        mountPath: /host/sys
        readOnly: true
  securityContext:
    privileged: true
    allowPrivilegeEscalation: true
    capabilities:
      add:
        - SYS_TIME
  extraEnv:
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName

controller:
  volumes:
    extra:
      - name: host-root
        hostPath:
          path: /
          type: Directory
      - name: host-proc
        hostPath:
          path: /proc
          type: Directory
      - name: host-sys
        hostPath:
          path: /sys
          type: Directory
```
<!-- textlint-enable terminology -->
