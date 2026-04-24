<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# large.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"resources":{"limits":{"cpu":"2000m","memory":"2Gi"},"requests":{"cpu":"500m","memory":"1Gi"}}}` | Sets resource requests and limits sized for large clusters (approximately up to 1000 nodes or heavy telemetry workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) for tuning. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Large preset

# -- Sets resource requests and limits sized for large clusters (approximately up to 1000 nodes or heavy telemetry
# workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/)
# for tuning.
# @section -- Alloy Configuration
alloy:
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi
```
<!-- textlint-enable terminology -->
