# Agent Autoscaling and Storage

This example shows how autoscaling and WAL storage can be set up
with [Grafana Agent Flow](https://grafana.com/docs/agent/latest/flow/) and this Helm chart.

The example uses a storage volume of 5Gi per agent instance, but this may need to be adjusted based on the number of
active series the agents are expected to scrape.

For more information, see [clustering documentation](https://grafana.com/docs/agent/latest/flow/concepts/clustering/).

```yaml
cluster:
  name: agent-autoscaling-and-storage-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

grafana-agent:
  agent:
    resources:
      requests:
        cpu: "1m"
        memory: "500Mi"

    storagePath: /var/lib/agent
    mounts:
      extra:
        - mountPath: /var/lib/agent
          name: agent-wal
  controller:
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 10
      targetCPUUtilizationPercentage: 0
      targetMemoryUtilizationPercentage: 80

    enableStatefulSetAutoDeletePVC: true
    volumeClaimTemplates:
      - metadata:
          name: agent-wal
        spec:
          accessModes: ["ReadWriteOnce"]
          storageClassName: "standard"
          resources:
            requests:
              storage: 5Gi
```
