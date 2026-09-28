<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Pod Security Standards: baseline
<!--alex disable host-hostess hostesses-hosts -->

This example deploys the chart into a cluster (or namespace) that enforces the
[`baseline` Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/).

The `baseline` policy blocks known privilege escalations: privileged containers, host namespaces (`hostNetwork`,
`hostPID`, `hostIPC`), `hostPath` volumes, and capabilities outside a small allowed set.

## Capabilities: `NET_RAW`

The chart's default collector security context does `drop: ["ALL"]` and then adds back the capabilities that a container
runtime (Docker/containerd) grants by default. That default set includes `NET_RAW`, and **`baseline` does not permit
`NET_RAW`** , because `NET_RAW` allows a container to craft and sniff raw network packets (spoofing, ARP/DNS poisoning).
So the chart's default collectors are rejected under `baseline` with:

```text
violates PodSecurity "baseline:latest": non-default capabilities (container "alloy" must not include "NET_RAW" in
securityContext.capabilities.add)
```

Alloy only uses `NET_RAW` when using the [`byela.ebpf` component](https://grafana.com/docs/alloy/latest/reference/components/beyla/beyla.ebpf/).

## `hostPath` volumes

`baseline` also forbids `hostPath` volumes, so any feature that reads from the node's filesystem cannot run under
`baseline`:

*   `hostMetrics` with the Alloy source, which reads `/proc`, `/sys`, and the host root
*   `nodeLogs`, which reads the systemd journal from the host
*   `podLogsViaLoki` and `podLogsViaOpenTelemetry`, which mounts `/var/log` to read the Pod logs

This example collects pod logs through the Kubernetes API instead, which needs no host access.

## Enforcing the policy

Pod Security Standards are enforced by the built-in
[Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) controller, which is
configured per namespace with labels. To enforce `baseline` on the namespace the chart is installed into:

```bash
kubectl label namespace <namespace> \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/enforce-version=latest
```

<!--alex enable host-hostess hostesses-hosts -->

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: pss-baseline-cluster

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

# The `baseline` Pod Security Standard forbids privileged pods, host namespaces,
# `hostPath` volumes, and capabilities outside a small allowed set.
#
# The chart's default collector security context does `drop: ["ALL"]` and then adds back
# the *container-runtime* default capabilities. That default set includes `NET_RAW`,
# which `baseline` does NOT permit (baseline allows the runtime defaults minus
# `NET_RAW`, because `NET_RAW` enables packet spoofing/sniffing). So the chart's default
# collectors are rejected by `baseline` with:
#
#   violates PodSecurity "baseline:latest": non-default capabilities
#   (container "alloy" must not include "NET_RAW" in securityContext.capabilities.add)
#
# Alloy does not need `NET_RAW` (or any of the other added capabilities) to scrape
# metrics, gather events, or read pod logs through the Kubernetes API, so the override
# below clears the added capabilities on each collector. No other `securityContext`
# changes are needed for `baseline`.
#
# Also avoid features that mount `hostPath` volumes, which `baseline` forbids: Host
# Metrics, Node Logs, and the filesystem-based Pod Logs collector. This example collects
# pod logs through the Kubernetes API instead, which needs no host access.

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

collectorCommon:
  alloy:
    alloy:
      securityContext:
        capabilities:
          add: ["CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "SETGID", "SETUID", "SETPCAP", "NET_BIND_SERVICE", "SYS_CHROOT", "MKNOD", "AUDIT_WRITE", "SETFCAP"]

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]

  alloy-singleton:
    presets: [singleton]

  alloy-logs:
    presets: [clustered, deployment]
```
<!-- textlint-enable terminology -->
