# IBM Cloud

The only difference from the default in running Kubernetes Monitoring on an IBM Cloud Kubernetes Cluster is the need to
add the `hostPath` volume mount for `/var/data` to the Grafana Alloy instance responsible for gathering pod logs. This is
because on the node, pod logs are stored in `/var/data`, with `/var/log/pods` being symlinked
to `/var/data/kubeletlogs/`.

Adding the mount for `/var/data` is sufficient to detect and gather the log files.

```yaml
cluster:
  name: ibm-cloud-test

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

alloy-logs:
  alloy:
    mounts:
      extra:
        - name: vardata
          mountPath: /var/data
  controller:
    volumes:
      extra:
        - name: vardata
          hostPath:
            path: /var/data
```
