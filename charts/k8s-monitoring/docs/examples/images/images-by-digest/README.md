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
        collector:
          image:
            digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
          configReloader:
            image:
              digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

clusterMetrics:
  enabled: true

  kube-state-metrics:
    image:
      sha: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

  node-exporter:
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

  windows-exporter:
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

  opencost:
    imagePullSecrets:
      - name: my-registry-creds
    opencost:
      exporter:
        image:
          # Not technically a digest, but a tag with a digest.
          tag: "1.115.0@sha256:fb6468a1ef45dbd4a9e521122c8d306f882bb33d1657d28d21aeaef79412e9e1"

  kepler:
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

autoInstrumentation:
  enabled: true
  beyla:
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

applicationObservability:
  enabled: true
  receivers:
    otlp:
      http:
        enabled: true

alloy-operator:
  image:
    digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

alloy-metrics:
  enabled: true
  image:
    digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  configReloader:
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

alloy-receiver:
  enabled: true
  image:
    digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
  configReloader:
    image:
      digest: sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```
<!-- textlint-enable terminology -->
