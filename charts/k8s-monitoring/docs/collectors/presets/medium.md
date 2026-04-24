<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# medium.yaml

<!-- textlint-disable terminology -->
## Values

### Alloy Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy | object | `{"resources":{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"250m","memory":"512Mi"}}}` | Sets resource requests and limits sized for medium clusters (approximately up to 250 nodes or moderate telemetry workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) for tuning. |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Medium preset

# -- Sets resource requests and limits sized for medium clusters (approximately up to 250 nodes or moderate telemetry
# workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/)
# for tuning.
# @section -- Alloy Configuration
alloy:
  resources:
    requests:
      cpu: 250m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi
```
<!-- textlint-enable terminology -->
