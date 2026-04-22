<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Kubernetes Manifests

This example demonstrates how to collect Kubernetes resource manifest changes using the `kubernetesManifests`
feature. It deploys `k8s-manifest-tail` to watch Kubernetes resources and log changes to stdout. Alloy tails
the pod logs and parses the structured OTLP JSON output to extract the resource action, kind, name, and
namespace before forwarding to Loki.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: kubernetes-manifests-cluster

destinations:
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

kubernetesManifests:
  enabled: true
  collector: alloy-singleton

podLogsViaLoki:
  enabled: true
  collector: alloy-logs

collectors:
  alloy-singleton:
    presets: [singleton]
    liveDebugging:
      enabled: true

  alloy-logs:
    presets: [filesystem-log-reader, daemonset]

telemetryServices:
  k8s-manifest-tail:
    deploy: true
    config:
      objects:
        - apiVersion: v1
          kind: Pod
        - apiVersion: apps/v1
          kind: Deployment
        - apiVersion: apps/v1
          kind: StatefulSet
        - apiVersion: apps/v1
          kind: DaemonSet
```
<!-- textlint-enable terminology -->
