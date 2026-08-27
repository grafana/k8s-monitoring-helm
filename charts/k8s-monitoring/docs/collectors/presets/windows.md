<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# windows.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"securityContext":{"allowPrivilegeEscalation":null,"capabilities":null,"seccompProfile":null}}` | Schedules Alloy onto Windows nodes and runs it as a process-isolated Windows container. It clears the Linux-only container `securityContext` fields (privilege escalation, capabilities, and seccomp profile) that Kubernetes rejects on Windows. This preset does not grant access to host resources; for workloads that need it (such as the Windows Event Logs feature), also apply the `windows-host-process` preset. Combine with a controller preset such as `daemonset` to run Alloy on every Windows node. |
| image | object | `{"tag":"v1.19.2-windowsservercore-ltsc2022"}` | Use the Windows (Windows Server Core) build of the Alloy image, since the operator otherwise defaults to the Linux image. Setting `image.tag` on the collector overrides this. KEEP IN SYNC when bumping the `alloy-operator` dependency: this must match the "Alloy Binary" version in `docs/Versions.md`. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"nodeSelector":{"kubernetes.io/os":"windows"}}` | Schedule the Alloy Pod onto Windows nodes. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| configReloader.enabled | bool | `false` |  |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Windows preset

# -- Schedules Alloy onto Windows nodes and runs it as a process-isolated Windows container. It clears the Linux-only
# container `securityContext` fields (privilege escalation, capabilities, and seccomp profile) that Kubernetes rejects
# on Windows. This preset does not grant access to host resources; for workloads that need it (such as the Windows
# Event Logs feature), also apply the `windows-host-process` preset. Combine with a controller preset such as
# `daemonset` to run Alloy on every Windows node.
# @section -- Alloy Configuration
alloy:
  # Clear the default Linux securityContext fields, which Kubernetes does not allow on Windows containers.
  securityContext:
    allowPrivilegeEscalation: null
    capabilities: null
    seccompProfile: null
# -- Use the Windows (Windows Server Core) build of the Alloy image, since the operator otherwise defaults to the Linux
# image. Setting `image.tag` on the collector overrides this. KEEP IN SYNC when bumping the `alloy-operator`
# dependency: this must match the "Alloy Binary" version in `docs/Versions.md`.
# @section -- Alloy Configuration
image:
  tag: v1.19.2-windowsservercore-ltsc2022
# -- Schedule the Alloy Pod onto Windows nodes.
# @section -- Other Values
controller:
  nodeSelector:
    kubernetes.io/os: windows
# The config reloader sidecar has no Windows image.
configReloader:
  enabled: false
```
<!-- textlint-enable terminology -->
