<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# VMware vSphere Kubernetes Service (VKS)

Broadcom's [VMware vSphere Kubernetes Service](https://www.vmware.com/products/cloud-infrastructure/vsphere-kubernetes-service)
(VKS) utilizes Kubernetes [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
at the `baseline` level by default. This example is configured to collect useful cluster and workload data while
keeping its workloads compatible with that policy: it enables cluster metrics, cluster events, Kubernetes manifests,
pod logs collected through the Kubernetes API, and cost metrics.

The baseline policy limits access to the host. These features will not work with the baseline policy:

*   Pod Logs via Loki or OpenTelemetry, which mount the host's `/var/log` directory. This example collects pod logs
    through the Kubernetes API instead, which avoids a host filesystem mount but depends on API access and the required
    permissions.
*   Beyla auto-instrumentation, which needs host-level access and elevated permissions.
*   Host Metrics using Node Exporter, Windows Exporter, or Kepler, which need host access.
*   Host Logs, which reads logs from the host.

For these features, use a namespace where the `privileged` Pod Security Standard is allowed.

To allow any chart feature from the perspective of Pod Security Standards, deploy into a namespace enforcing
`privileged` instead of `baseline`:

```bash
kubectl label namespace <namespace> \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/enforce-version=latest
```

This removes Pod Security Admission's baseline restrictions for workloads in that namespace. Other cluster policies
and permissions still apply.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: vks-cluster

destinations:
  metrics-destination:
    type: prometheus
    url: http://prometheus.example.com/api/prom/push

  loki:
    type: loki
    url: http://loki.example.com/loki/api/v1/push
    tenantId: "1"

clusterMetrics:
  enabled: true
  collector: alloy-metrics

costMetrics:
  enabled: true
  collector: alloy-metrics

clusterEvents:
  enabled: true
  collector: alloy-singleton

kubernetesManifests:
  enabled: true
  collector: alloy-singleton

podLogsViaKubernetesApi:
  enabled: true
  collector: alloy-logs

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
  kube-state-metrics:
    deploy: true
  opencost:
    deploy: true
    metricsSource: metrics-destination
    opencost:
      exporter:
        defaultClusterId: vks-cluster
      prometheus:
        external:
          url: http://prometheus.example.com/api/prom

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
  alloy-singleton:
    presets: [singleton]
  alloy-logs:
    presets: [clustered, deployment]

# Remove the "NET_RAW" capability by redefining the add list. That capability is not permitted in the baseline pod
# security standard.
collectorCommon:
  alloy:
    alloy:
      securityContext:
        capabilities:
          add: ["CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "SETGID", "SETUID", "SETPCAP", "NET_BIND_SERVICE", "SYS_CHROOT", "MKNOD", "AUDIT_WRITE", "SETFCAP"]
```
<!-- textlint-enable terminology -->
