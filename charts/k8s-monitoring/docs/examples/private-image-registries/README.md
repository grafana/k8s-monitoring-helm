<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Private Image Registries

This example shows how to override the container image registries for every subchart. This can be used to support
air-gapped environments, or in environments where you might not want to use public image registries.

This example shows using the `global` object to set registry and pull secrets for most subcharts. However, subcharts
use different methods, even within the global objects, so it needs to be defined in both ways.

If you do not want to use the `global` object, registry and pull secrets can be set on each subchart individually.

## Values

```yaml
---
cluster:
  name: private-image-registries-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

  - name: tempo
    type: otlp
    url: http://tempo.tempo.svc:4317

# Dependent charts use two methods for global image registry and pull secrets
# so we need to define it both ways.
global:
  image:
    registry: my.registry.com
    pullSecrets:
      - name: my-registry-creds
  imageRegistry: my.registry.com
  imagePullSecrets:
    - name: my-registry-creds

clusterMetrics:
  enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true
```
