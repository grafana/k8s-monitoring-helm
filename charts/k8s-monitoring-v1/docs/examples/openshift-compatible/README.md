# OpenShift Compatible

This example shows the modifications from the [default](../default-values) to deploy Kubernetes Monitoring on an OpenShift cluster.

These modifications skip the deployment of kube-state-metrics and Node Exporter, since they will already be present on
the cluster, and adjust the configuration to Grafana Alloy to find those existing components.
It also modifies Grafana Alloy to lock down security and permissions.

The `platform: openshift` switch also creates SecurityContextConstraints objects that modifies the permissions for the
Grafana Alloy.

Note that these alloy pods cannot enable `readOnlyRootFilesystem` because they require being able to write to their
storage path, which defaults to `/tmp/alloy`.

```yaml
cluster:
  name: openshift-compatible-test
  platform: openshift

externalServices:
  prometheus:
    host: https://prometheus.example.com
    proxyURL: http://192.168.1.100:8080
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"

  loki:
    host: https://prometheus.example.com
    proxyURL: http://192.168.1.100:8080
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"

metrics:
  kube-state-metrics:
    service:
      port: https-main
      isTLS: true

  node-exporter:
    labelMatchers:
      app.kubernetes.io/name: node-exporter
    service:
      isTLS: true

kube-state-metrics:
  enabled: false

prometheus-node-exporter:
  enabled: false

alloy:
  alloy:
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
        add: ["CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "SETGID", "SETUID", "SETPCAP", "NET_BIND_SERVICE", "NET_RAW", "SYS_CHROOT", "MKNOD", "AUDIT_WRITE", "SETFCAP"]
      seccompProfile:
        type: "RuntimeDefault"

alloy-logs:
  alloy:
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
        add: ["CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "SETGID", "SETUID", "SETPCAP", "NET_BIND_SERVICE", "NET_RAW", "SYS_CHROOT", "MKNOD", "AUDIT_WRITE", "SETFCAP"]
      privileged: false
      runAsUser: 0
  global:
    podSecurityContext:
      seLinuxOptions:
        type: spc_t

alloy-events:
  alloy:
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
        add: ["CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "SETGID", "SETUID", "SETPCAP", "NET_BIND_SERVICE", "NET_RAW", "SYS_CHROOT", "MKNOD", "AUDIT_WRITE", "SETFCAP"]
      seccompProfile:
        type: "RuntimeDefault"
```
