<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# small.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Sets resource requests and limits sized for small clusters (approximately up to 50 nodes or light telemetry workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) for tuning. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Small preset

# -- Sets resource requests and limits sized for small clusters (approximately up to 50 nodes or light telemetry
# workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/)
# for tuning.
# @section -- Alloy Configuration
alloy:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
```
<!-- textlint-enable terminology -->
