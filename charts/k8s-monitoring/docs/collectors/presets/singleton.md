<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# singleton.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"replicas":1,"type":"deployment"}` | Configures Alloy to run as a single-instance, protecting workloads that would result in duplicated data if run on multiple replicas. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Singleton preset

# -- Configures Alloy to run as a single-instance, protecting workloads that would result in duplicated data if run on
# multiple replicas.
# @section -- Alloy Configuration
controller:
  type: deployment
  replicas: 1
```
<!-- textlint-enable terminology -->
