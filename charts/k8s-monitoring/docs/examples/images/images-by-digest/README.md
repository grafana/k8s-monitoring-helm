<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Images by Digest

This example shows how to reference the container images used by their digest. This is useful for ensuring that the
exact version of an image is used, as opposed to using a tag which may change over time. However, care should be taken
to ensure that the digest is correct and corresponds to the intended image version. This example uses a contrived
digest for demonstration purposes.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: images-by-digest-example-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

  tempo:
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
        collector:
          image:
            digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
          configReloader:
            image:
              digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

clusterMetrics:
  enabled: true
  collector: alloy-metrics

costMetrics:
  enabled: true
  collector: alloy-metrics

hostMetrics:
  enabled: true
  collector: alloy-metrics
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true
  energyMetrics:
    enabled: true

autoInstrumentation:
  enabled: true
  collector: alloy-metrics
  beyla:
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

applicationObservability:
  enabled: true
  collector: alloy-receiver
  receivers:
    otlp:
      http:
        enabled: true

alloy-operator:
  image:
    digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  waitForAlloyRemoval:
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

collectorCommon:
  alloy:
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
    configReloader:
      image:
        digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

collectors:
  alloy-metrics: {}

  alloy-receiver: {}

telemetryServices:
  kube-state-metrics:
    deploy: true
    image:
      sha: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  node-exporter:
    deploy: true
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  windows-exporter:
    deploy: true
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  kepler:
    deploy: true
  opencost:
    deploy: true
    metricsSource: prometheus
    imagePullSecrets:
      - name: my-registry-creds
    opencost:
      exporter:
        defaultClusterId: images-by-digest-example-cluster
        image:
          # Not technically a digest, but a tag with a digest.
          tag: "1.115.0@sha256:fb6468a1ef45dbd4a9e521122c8d306f882bb33d1657d28d21aeaef79412e9e1"
      prometheus:
        external:
          url: http://prometheus.prometheus.svc:9090/api/v1/query
```
<!-- textlint-enable terminology -->
