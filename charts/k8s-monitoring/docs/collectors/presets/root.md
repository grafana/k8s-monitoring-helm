<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# root.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"securityContext":{"allowPrivilegeEscalation":true,"privileged":true,"runAsGroup":0,"runAsUser":0}}` | Runs Alloy as a privileged root container by setting only the `securityContext` (privileged, root user and group, and allowed privilege escalation). Combine with the `host-network`, `host-storage`, and `host-cgroup` presets to grant the specific host access a collector needs. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Root preset

# -- Runs Alloy as a privileged root container by setting only the `securityContext` (privileged, root user and
# group, and allowed privilege escalation). Combine with the `host-network`, `host-storage`, and `host-cgroup`
# presets to grant the specific host access a collector needs.
# @section -- Alloy Configuration
alloy:
  securityContext:
    allowPrivilegeEscalation: true
    privileged: true
    runAsGroup: 0
    runAsUser: 0
```
<!-- textlint-enable terminology -->
