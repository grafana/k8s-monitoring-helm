<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Global Private Image Registries

This example shows how to override the container image registries for every subchart. This can be used to support
air-gapped environments, or in environments where you might not want to use public image registries.

This example shows using the `global` object to set registry and pull secrets for most subcharts. However, subcharts
use different methods, even within the global objects, so it needs to be defined in both ways.

*   `global.image.registry` & `global.image.pullSecrets` - This applies to Alloy, Alloy Operator and Beyla.
*   `global.imageRegistry` & `global.imagePullSecrets` - This applies to kube-state-metrics, Node Exporter and Windows Exporter
*   Exceptions:
    *   Kepler does not utilize global settings. You must use:
        *   `clusterMetrics.kepler.image.repository` - The *full* image repository path.
        *   `clusterMetrics.kepler.imagePullSecrets`
    *   OpenCost also does not utilize global settings. You must use:
        *   `clusterMetrics.opencost.imagePullSecrets`
        *   `clusterMetrics.opencost.exporter.image.registry`

If you do not want to use the `global` object, registry and pull secrets can be set on each subchart
[individually](../individual).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: global-private-image-registries-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

  - name: tempo
    type: otlp
    url: http://tempo.tempo.svc:3200/api/v1/metrics
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}
    processors:
      tailSampling:
        enabled: true
        policies:
          - name: always_sample-policy
            type: always_sample

# Dependent charts use two methods for global image registry and pull secrets
# so we need to define it both ways.
global:
  # Required for Alloy, Alloy Operator and Beyla
  image:
    registry: my.registry.com
    pullSecrets:
      - name: my-registry-creds

  # Required for kube-state-metrics, Node Exporter and Windows Exporter
  imageRegistry: my.registry.com
  imagePullSecrets:
    - name: my-registry-creds

clusterMetrics:
  enabled: true

costMetrics:
  enabled: true

hostMetrics:
  enabled: true
  energyMetrics:
    enabled: true
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true

podLogs:
  enabled: true

applicationObservability:
  enabled: true
  receivers:
    otlp:
      http:
        enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true

alloy-receiver:
  enabled: true

telemetryServices:
  # Kepler does not utilize the global image registry settings
  kepler:
    deploy: true
    image:
      repository: my.registry.com/sustainable_computing_io/kepler
    imagePullSecrets:
      - name: my-registry-creds

  # OpenCost does not utilize the global image registry settings
  opencost:
    imagePullSecrets:
      - name: my-registry-creds
    opencost:
      exporter:
        image:
          registry: my.registry.com

  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
