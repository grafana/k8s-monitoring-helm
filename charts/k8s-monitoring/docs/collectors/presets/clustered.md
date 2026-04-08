<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# clustered.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"clustering":{"enabled":true}}` | Enables Alloy clustering to distribute telemetry gathering compatible work across multiple replicas. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Clustered preset

# -- Enables Alloy clustering to distribute telemetry gathering compatible work across multiple replicas.
# @section -- Alloy Configuration
alloy:
  clustering:
    enabled: true
```
<!-- textlint-enable terminology -->
