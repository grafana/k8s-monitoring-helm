<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Collector Storage Example

This example shows how to use volumes to enhance the abilities of metric scraping and log gathering. Metric scraping can
utilize a Write-Ahead Log (WAL) to store metrics in case of a scrape failure. Log gathering can utilize a volume to
store log file positions, so it knows where to start reading logs from after a restart.

## Values

```yaml
---
cluster:
  name: collector-storage-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

clusterMetrics:
  enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true
  alloy:
    storagePath: /var/lib/alloy
    mounts:
      extra:
        - name: alloy-wal
          mountPath: /var/lib/alloy

  controller:
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
  enabled: true
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
