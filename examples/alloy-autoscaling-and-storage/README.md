# Alloy Autoscaling and Storage

This example shows how autoscaling and WAL storage can be set up
with [Grafana Alloy](https://grafana.com/docs/alloy/latest/) and this Helm chart.

The example uses a storage volume of 5Gi per Alloy instance, but this may need to be adjusted based on the number of
active series the Alloy instances are expected to scrape.

For more information, see [clustering documentation](https://grafana.com/docs/alloy/latest/concepts/clustering/).

```yaml
cluster:
  name: alloy-autoscaling-and-storage-test

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

alloy:
  alloy:
    resources:
      requests:
        cpu: "1m"
        memory: "500Mi"

    storagePath: /var/lib/alloy
    mounts:
      extra:
        - name: alloy-wal
          mountPath: /var/lib/alloy
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
          name: alloy-wal
        spec:
          accessModes: ["ReadWriteOnce"]
          storageClassName: "standard"
          resources:
            requests:
              storage: 5Gi

alloy-logs:
  alloy:
    storagePath: /var/lib/alloy
    mounts:
      extra:
        - name: alloy-log-positions
          mountPath: /var/lib/alloy
  controller:
    volumes:
      extra:
        - name: alloy-log-positions
          hostPath:
            path: /var/alloy-log-storage
            type: DirectoryOrCreate
```
