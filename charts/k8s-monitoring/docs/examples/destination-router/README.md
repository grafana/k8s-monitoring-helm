<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Destination Router

This example shows how to use the `router` destination to fan pod logs out to different real
destinations based on the Kubernetes namespace they came from, without teaching the
`podLogsViaOpenTelemetry` feature anything about tenant-specific plumbing.

A router is not a real telemetry backend. It is a virtual destination that inspects an attribute
(or the mapped label, for label-based collection pipelines) on each record and forwards it to one
or more real downstream destinations. In this example, the router is named `tenantRouter` and
routes on the default attribute, `k8s.namespace.name`:

```yaml
destinations:
  tenantRouter:
    type: router
    routes:
      - match:
          equals: tenant-a
        destinations:
          - stack-a
    defaultDestinations:
      - platform
```

Pod logs collected from the `tenant-a` namespace are sent to the `stack-a` destination. Pod logs
from every other namespace fall back to `defaultDestinations` and are sent to `platform`.

Because routers are excluded from implicit destination selection, the feature that should use one
must name it explicitly:

```yaml
podLogsViaOpenTelemetry:
  enabled: true
  destinations:
    - tenantRouter
```

For a complete reference of the router configuration options, routing semantics, and how routing
behaves across the different collection pipelines (scraped metrics, Loki logs, Pyroscope profiles,
and OpenTelemetry Protocol), refer to [Destination routing](../../DestinationRouting.md).

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: destination-router

destinations:
  stack-a:
    type: otlp
    protocol: http
    url: http://tempo-stack-a.tempo.svc:443/otlp
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: true}
  platform:
    type: otlp
    protocol: http
    url: http://tempo-platform.tempo.svc:443/otlp
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: true}
  tenantRouter:
    type: router
    # Routes on the default attribute, k8s.namespace.name, which is automatically mapped to the
    # "namespace" label for label-based collection pipelines.
    routes:
      - match:
          equals: tenant-a
        destinations:
          - stack-a
    # MANDATORY: every router must define at least one fallback destination for records that
    # don't match any route.
    defaultDestinations:
      - platform

podLogsViaOpenTelemetry:
  enabled: true
  collector: alloy-logs
  # Routers are excluded from implicit destination selection, so they must be named explicitly.
  destinations:
    - tenantRouter

collectors:
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
    alloy:
      stabilityLevel: public-preview
```
<!-- textlint-enable terminology -->
