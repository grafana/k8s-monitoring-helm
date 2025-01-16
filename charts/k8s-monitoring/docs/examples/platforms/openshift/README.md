<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# OpenShift

This example shows the modifications requires to deploy to an OpenShift cluster.

These modifications skip the deployment of kube-state-metrics and Node Exporter, since they will already be present on
the cluster, and adjust the configuration to Grafana Alloy to find those existing components.
It also modifies Grafana Alloy to lock down security and permissions.

The `platform: openshift` switch also creates SecurityContextConstraints objects that modifies the permissions for the
Grafana Alloy.

Note that these alloy pods cannot enable `readOnlyRootFilesystem` because they require being able to write to their
storage path, which defaults to `/tmp/alloy`.

## Values

```yaml
---
cluster:
  name: openshift-cluster

global:
  platform: openshift

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  - name: loki
    type: loki
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  kube-state-metrics:
    deploy: false
    namespace: openshift-monitoring
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    service:
      scheme: https
      portName: https-main
  node-exporter:
    deploy: false
    namespace: openshift-monitoring
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    service:
      scheme: https
      portName: https

  kepler:
    enabled: true

clusterEvents:
  enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true
  alloy:
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        add:
          - CHOWN
          - DAC_OVERRIDE
          - FOWNER
          - FSETID
          - KILL
          - SETGID
          - SETUID
          - SETPCAP
          - NET_BIND_SERVICE
          - NET_RAW
          - SYS_CHROOT
          - MKNOD
          - AUDIT_WRITE
          - SETFCAP
        drop:
          - ALL
      seccompProfile:
        type: RuntimeDefault
alloy-singleton:
  enabled: true
  alloy:
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        add:
          - CHOWN
          - DAC_OVERRIDE
          - FOWNER
          - FSETID
          - KILL
          - SETGID
          - SETUID
          - SETPCAP
          - NET_BIND_SERVICE
          - NET_RAW
          - SYS_CHROOT
          - MKNOD
          - AUDIT_WRITE
          - SETFCAP
        drop:
          - ALL
      seccompProfile:
        type: RuntimeDefault
alloy-logs:
  enabled: true
  alloy:
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        add:
          - CHOWN
          - DAC_OVERRIDE
          - FOWNER
          - FSETID
          - KILL
          - SETGID
          - SETUID
          - SETPCAP
          - NET_BIND_SERVICE
          - NET_RAW
          - SYS_CHROOT
          - MKNOD
          - AUDIT_WRITE
          - SETFCAP
        drop:
          - ALL
      privileged: false
      runAsUser: 0
  global:
    podSecurityContext:
      seLinuxOptions:
        type: spc_t```
