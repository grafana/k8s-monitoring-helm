<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# host-network.yaml

<!-- textlint-disable terminology -->
## Values

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"dnsPolicy":"ClusterFirstWithHostNet","hostNetwork":true,"hostPID":true}` | Runs Alloy in the host's PID and network namespaces, with a matching `dnsPolicy` so cluster DNS resolution keeps working. This lets Alloy observe host-level processes and networking, and is required for Beyla auto-instrumentation. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Host Network preset

# -- Runs Alloy in the host's PID and network namespaces, with a matching `dnsPolicy` so cluster DNS resolution keeps
# working. This lets Alloy observe host-level processes and networking, and is required for Beyla auto-instrumentation.
# @section -- Other Values
controller:
  hostPID: true
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
```
<!-- textlint-enable terminology -->
