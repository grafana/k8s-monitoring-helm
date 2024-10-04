<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: features/profiling/default/values.yaml

## Values

```yaml
---
cluster:
  name: profiling-cluster

destinations:
  - name: pyroscope
    type: pyroscope
    url: http://pyroscope.pyroscope.svc:4040

profiling:
  enabled: true

alloy-profiles:
  enabled: true
```
