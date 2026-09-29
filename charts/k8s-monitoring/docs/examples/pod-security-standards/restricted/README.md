<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Pod Security Standards: restricted
<!--alex disable host-hostess hostesses-hosts -->

This example deploys the chart into a cluster (or namespace) that enforces the
[`restricted` Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), the
strictest built-in policy.

On top of everything `baseline` forbids, `restricted` requires every container to:

*   run as a non-root user (`runAsNonRoot: true`, and a non-zero `runAsUser` if set)
*   set `allowPrivilegeEscalation: false`
*   drop **all** capabilities and add back at most `NET_BIND_SERVICE`
*   set `seccompProfile.type` to `RuntimeDefault` or `Localhost`

The chart's default collector security context drops all capabilities but adds several back (such as `CHOWN`, `NET_RAW`,
and `SYS_CHROOT`) and does not force a non-root user, so the defaults are rejected under `restricted`. This example
overrides the security context on each Alloy collector to remove the added capabilities, pin a non-root user, and set a
seccomp profile.

As with `baseline`, features that mount `hostPath` volumes cannot run under `restricted`:

*   `hostMetrics` with the Alloy source, which reads `/proc`, `/sys`, and the host root
*   `nodeLogs`, which reads the systemd journal from the host
*   `podLogsViaLoki` and `podLogsViaOpenTelemetry`, which mounts `/var/log` to read the Pod logs

This example collects pod logs through the Kubernetes API instead, which needs no host access.

## Enforcing the policy

Pod Security Standards are enforced by the built-in
[Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) controller, which is
configured per namespace with labels. To enforce `restricted` on the namespace the chart is installed into:

```bash
kubectl label namespace <namespace> \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest
```

<!--alex enable host-hostess hostesses-hosts -->

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: pss-restricted-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write

  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

# The `restricted` Pod Security Standard is the strictest built-in policy. On top of the
# `baseline` requirements, every container must:
#
#   * set `runAsNonRoot: true` (and, if `runAsUser` is set, it must be non-zero)
#   * set `allowPrivilegeEscalation: false`
#   * drop ALL capabilities and add back at most `NET_BIND_SERVICE`
#   * set `seccompProfile.type` to `RuntimeDefault` or `Localhost`
#
# The chart's default collector security context drops ALL capabilities but adds several
# back (CHOWN, NET_RAW, SYS_CHROOT, ...) and does not force a non-root user, so it is
# rejected by `restricted`. The overrides below bring each Alloy collector into
# compliance. kube-state-metrics and the Alloy Operator already ship compliant contexts;
# the Operator only needs a `seccompProfile` added.
#
# As with `baseline`, features that mount `hostPath` volumes (Host Metrics, Node Logs,
# and the filesystem Pod Logs collector) cannot run under `restricted`. This example
# collects pod logs through the Kubernetes API instead.

clusterMetrics:
  enabled: true
  collector: alloy-metrics

clusterEvents:
  enabled: true
  collector: alloy-singleton

podLogsViaKubernetesApi:
  enabled: true
  collector: alloy-logs
  namespaces:
    - grafana
    - loki
    - prometheus

telemetryServices:
  kube-state-metrics:
    deploy: true

alloy-operator:
  podSecurityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault

collectorCommon:
  alloy:
    alloy:
      securityContext:
        runAsNonRoot: true
        runAsUser: 473
        runAsGroup: 473
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: false
        capabilities:
          drop: ["ALL"]
          # Clear the capabilities the chart adds by default; `restricted` permits none
          # of them (at most NET_BIND_SERVICE, which Alloy does not need here).
          add: []
        seccompProfile:
          type: RuntimeDefault
    global:
      podSecurityContext:
        runAsNonRoot: true
        runAsUser: 473
        runAsGroup: 473
        fsGroup: 473
        seccompProfile:
          type: RuntimeDefault

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]

  alloy-singleton:
    presets: [singleton]

  alloy-logs:
    presets: [clustered, deployment]
```
<!-- textlint-enable terminology -->
