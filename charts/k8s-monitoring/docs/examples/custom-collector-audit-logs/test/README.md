<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: custom-collector-audit-logs/test/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: custom-collector-audit-logs-test

destinations:
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

selfReporting:
  enabled: false

collectors:
  alloy-audit-logs:
    presets: [daemonset]
    includeDestinations: [loki]
    alloy:
      extraEnv:
        - name: CLUSTER_NAME
          value: custom-collector-audit-logs-test
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
