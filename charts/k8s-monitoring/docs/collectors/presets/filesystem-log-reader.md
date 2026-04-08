<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# filesystem-log-reader.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"mounts":{"dockercontainers":true,"varlog":true}}` | Configures Alloy to mount the /var/log from the Node's file system. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Filesystem log reader preset

# -- Configures Alloy to mount the /var/log from the Node's file system.
# @section -- Alloy Configuration
alloy:
  mounts:
    # Mount `/var/log` from the host into the container for log collection.
    varlog: true

    # Also mount `/var/lib/docker/containers` from the host into the container for log collection.
    dockercontainers: true
```
<!-- textlint-enable terminology -->
