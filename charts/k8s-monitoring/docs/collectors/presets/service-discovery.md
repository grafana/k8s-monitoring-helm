<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# service-discovery.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| remoteConfig | object | `{"extraAttributes":{"service-discovery":true}}` | Sets the "service-discovery" attribute when using remote configuration, which indicates that this collector instance should get cluster service discovery configuration. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Service Discovery preset

# -- Sets the "service-discovery" attribute when using remote configuration, which indicates that this collector
# instance should get cluster service discovery configuration.
# @section -- Alloy Configuration
remoteConfig:
  extraAttributes:
    service-discovery: true
```
<!-- textlint-enable terminology -->
