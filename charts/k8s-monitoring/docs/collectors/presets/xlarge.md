<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# xlarge.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"resources":{"limits":{"cpu":"4000m","memory":"4Gi"},"requests":{"cpu":"1000m","memory":"2Gi"}}}` | Sets resource requests and limits sized for very large clusters (approximately 1000+ nodes or heavy telemetry workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) for tuning. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# XLarge preset

# -- Sets resource requests and limits sized for very large clusters (approximately 1000+ nodes or heavy telemetry
# workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/)
# for tuning.
# @section -- Alloy Configuration
alloy:
  resources:
    requests:
      cpu: 1000m
      memory: 2Gi
    limits:
      cpu: 4000m
      memory: 4Gi
```
<!-- textlint-enable terminology -->
