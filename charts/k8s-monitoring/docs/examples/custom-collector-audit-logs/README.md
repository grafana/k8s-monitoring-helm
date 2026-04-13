<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Custom Collector for Kubernetes Audit Logs

This example shows how to add a separate Alloy collector as a DaemonSet on control plane nodes to collect Kubernetes
audit logs. It demonstrates how to:

-   Define a custom collector with `extraConfig` for reading audit log files.
-   Use `nodeSelector` to schedule the collector only on control plane nodes.
-   Use `tolerations` to allow the collector to run on tainted control plane nodes.
-   Mount the host audit log directory using extra volumes and volume mounts.

The `alloy-audit-logs` collector uses a `local.file_match` component to discover audit log files on the host and a
`loki.source.file` component to tail them and forward to a Loki destination.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: custom-collector-audit-logs-cluster

destinations:
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

selfReporting:
  enabled: false

collectors:
  alloy-audit-logs:
    presets: [daemonset]
    includeDestinations: [loki]
    alloy:
      extraEnv:
        - name: CLUSTER_NAME
          value: custom-collector-audit-logs-cluster
      mounts:
        extra:
          - name: audit-logs
            mountPath: /var/log/kubernetes/audit
            readOnly: true
    controller:
      nodeSelector:
        node-role.kubernetes.io/control-plane: ""
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          effect: NoSchedule
          operator: Exists
      volumes:
        extra:
          - name: audit-logs
            hostPath:
              path: /var/log/kubernetes/audit
              type: DirectoryOrCreate
    extraConfig: |
      local.file_match "audit_logs" {
        path_targets = [{
          __path__  = "/var/log/kubernetes/audit/*.log",
          job       = "integrations/kubernetes-audit",
          cluster   = env("CLUSTER_NAME"),
          component = "audit",
        }]
      }

      loki.source.file "audit_logs" {
        targets    = local.file_match.audit_logs.targets
        forward_to = [loki.write.loki.receiver]
      }
```
<!-- textlint-enable terminology -->
