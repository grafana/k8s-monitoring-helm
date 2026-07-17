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
| alloy | object | `{"command":["%CONTAINER_SANDBOX_MOUNT_POINT%\\Program Files\\GrafanaLabs\\Alloy\\alloy.exe"]}` | Configures Alloy to run on Windows nodes as a HostProcess container. It schedules Alloy onto Windows nodes, runs the Windows Alloy binary from its in-container sandbox path, and applies the Windows-specific `securityContext` needed for HostProcess pods (clearing the Linux capabilities and seccomp profile that don't apply on Windows). Combine with a controller preset such as `daemonset` to run Alloy on every Windows node. |
| image | object | `{"tag":"v1.17.1-windowsservercore-ltsc2022"}` | Use the Windows HostProcess (Windows Server Core) build of the Alloy image, since the operator otherwise defaults to the Linux image. Setting `image.tag` on the collector overrides this. KEEP IN SYNC when bumping the `alloy-operator` dependency: this must match the "Alloy Binary" version in `docs/Versions.md`. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"nodeSelector":{"kubernetes.io/os":"windows"}}` | Schedule the Alloy Pod onto Windows nodes. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Windows preset

# -- Configures Alloy to run on Windows nodes as a HostProcess container. It schedules Alloy onto Windows nodes, runs
# the Windows Alloy binary from its in-container sandbox path, and applies the Windows-specific `securityContext`
# needed for HostProcess pods (clearing the Linux capabilities and seccomp profile that don't apply on Windows).
# Combine with a controller preset such as `daemonset` to run Alloy on every Windows node.
# @section -- Alloy Configuration
alloy:
  # Override the entrypoint to the Alloy binary inside the HostProcess container's sandbox mount point.
  command:
    - '%CONTAINER_SANDBOX_MOUNT_POINT%\Program Files\GrafanaLabs\Alloy\alloy.exe'

  # Replace the default Linux securityContext with Windows HostProcess settings. The Linux-only fields must be cleared
  # or Kubernetes rejects the Pod on Windows nodes.
#  securityContext:
#    allowPrivilegeEscalation: null
#    capabilities: null
#    seccompProfile: null
#    windowsOptions:
#      hostProcess: true
#      runAsUserName: "NT AUTHORITY\\SYSTEM"

# -- Use the Windows HostProcess (Windows Server Core) build of the Alloy image, since the operator otherwise defaults
# to the Linux image. Setting `image.tag` on the collector overrides this. KEEP IN SYNC when bumping the
# `alloy-operator` dependency: this must match the "Alloy Binary" version in `docs/Versions.md`.
# @section -- Alloy Configuration
image:
  tag: v1.17.1-windowsservercore-ltsc2022

# -- Run the Alloy Pod as a Windows HostProcess pod, so every container in the Pod (including the config reloader)
# inherits the HostProcess settings.
# @section -- Other Values
#global:
#  podSecurityContext:
#    windowsOptions:
#      hostProcess: true
#      runAsUserName: "NT AUTHORITY\\SYSTEM"

# -- Schedule the Alloy Pod onto Windows nodes.
# @section -- Other Values
controller:
  nodeSelector:
    kubernetes.io/os: windows
```
<!-- textlint-enable terminology -->
