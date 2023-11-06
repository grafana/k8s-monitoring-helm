# Control plane metrics

This example shows a deployment that enables gathering of [control plane metrics](https://kubernetes.io/docs/concepts/cluster-administration/system-metrics/#kube-scheduler-metrics):

Note that this requires the services expose their metrics endpoints. This may require changes to how your cluster is deployed.

Metric sources available:
* API Server
* Kube Controller Manager
* Kube Proxy
* Kube Scheduler

```yaml
cluster:
  name: control-plane-metrics-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    tenantId: 1000
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

metrics:
  apiserver:
    enabled: true
  kubeControllerManager:
    enabled: true
  kubeProxy:
    enabled: true
  kubeScheduler:
    enabled: true
```
