# EKS Fargate

AWS EKS Fargate Kubernetes clusters have a fully managed control plane, which reduce the management needs of the user,
but need extra consideration because they often have restrictions around DaemonSets and node access. This prevents
services like Node Exporter from working properly. It also has implications for how Pod logs are gathered, since the
typical method is to deploy Grafana Alloy as a Daemonset with HostPath volume mounts to gather the log files.
Consequently, Alloy must be deployed to use the
[Kubernetes API log gathering](https://grafana.com/docs/alloy/latest/reference/components/loki.source.kubernetes/)
method instead.

Missing Node Exporter metrics is likely fine, because users of these clusters should not need concern themselves with
the health of the nodes. That's the responsibility of the cloud provider.

This example shows how to disable Node Exporter and gather Pod logs via the Kubernetes API:

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
    gatherMethod: api

prometheus-node-exporter:
  enabled: false

alloy-logs:
  alloy:
    clustering: {enabled: true}
    mounts:
      varlog: false
  controller:
    replicas: 2
    type: deployment
```
