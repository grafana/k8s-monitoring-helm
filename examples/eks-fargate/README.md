# EKS Fargate

AWS EKS Fargate Kubernetes clusters have a fully managed control plane, which reduce the management needs of the user,
but need special consideration because they often have special restrictions around DaemonSets and node access. This
prevents services like Node Exporter and the Grafana Agent for capturing pod logs from working properly.

Missing Node Exporter metrics is likely fine, because users of these clusters should not need concern themselves with
the health of the nodes. That's the responsibility of the cloud provider.

Missing pod logs could be addressed by accessing cluster logs from
[CloudWatch to Loki](https://grafana.com/docs/loki/latest/send-data/lambda-promtail/).

This example shows how to disable Node Exporter and Pod logs to enable metrics and cluster events:

```yaml
cluster:
  name: eks-fargate-test

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

metrics:
  node-exporter:
    enabled: false

logs:
  pod_logs:
    enabled: false

prometheus-node-exporter:
  enabled: false
```
