# Cluster with pvc

This example shows how autoscaling can be setup with [Grafana Agent Flow](https://grafana.com/docs/agent/latest/flow/) and this Helm chart.

Note, Clustering is BETA as of 2024/01/11.  

The configuration is specific to GKE, especially storageClassName. This chart also assumes that HPA is configured correctly. 

For more information, see [clustering documentation](https://grafana.com/docs/agent/latest/flow/concepts/clustering/).


```yaml
cluster:
  name: cluster-with-pvc-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
    externalLabels:
      region: southwest
      tenant: widgetco
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
    externalLabels:
      region: southwest
      tenant: widgetco

grafana-agent:
  agent:
    resources: 
      requests:
        cpu: "1m"
        memory: "500Mi"
    clustering:
      enabled: true
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
# Ensure Helm 0.8.3 of k8s-monitoring, K8s > 1.23
    enableStatefulSetAutoDeletePVC: true
    volumeClaimTemplates: 
      - metadata:
          name: agent-wal
        spec:
          accessModes: [ "ReadWriteOnce" ]
          storageClassName: "standard"
          resources:
            requests:
              storage: 1Gi
```
