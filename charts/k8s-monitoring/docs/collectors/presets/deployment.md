<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# deployment.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"replicas":1,"type":"deployment"}` | Configures Alloy to run as a Deployment, with a default of 1 replica. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Deployment preset

# -- Configures Alloy to run as a Deployment, with a default of 1 replica.
# @section -- Alloy Configuration
controller:
  type: deployment
  replicas: 1
```
<!-- textlint-enable terminology -->
