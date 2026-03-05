<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Sharded kube-state-metrics

This example demonstrates how to [shard kube-state-metrics](https://github.com/kubernetes/kube-state-metrics#scaling-kube-state-metrics)
to improve scalability. This is useful when your Kubernetes cluster has a large number of objects and kube-state-metrics
is struggling to keep up. The symptoms of this might be:

*   It takes longer than 60 seconds to scrape kube-state-metrics, which is longer than the scrape interval.
*   The sheer amount of metric data coming from kube-state-metrics is causing Alloy to spike its required resources.
*   kube-state-metrics itself might not be able to keep up with the number of objects in the cluster.

By increasing the number of replicas and enabling [automatic sharding](https://github.com/kubernetes/kube-state-metrics#automated-sharding),
kube-state-metrics will automatically distribute the resources on the cluster across the shards.

## Enabling sharding

To enable sharding, you need to enable the `autosharding` flag in the kube-state-metrics section, and set the desired
number of replicas.

**Note**: If you are upgrading a k8s-monitoring Helm release to enabling kube-state-metrics sharding, you will need to
delete the existing kube-state-metrics Service. The changes due to sharding make it so Kubernetes will not be able to
update the Service in place. After deleting the Service, you can upgrade as normal.

```shell
$ kubectl delete service grafana-k8s-monitoring-kube-state-metrics
$ helm upgrade grafana-k8s-monitoring grafana/k8s-monitoring -f values.yaml
```

## Changing replicas

Whenever the number of replicas changes, there are two scenarios to consider. Your requirements will dictate which one
is best for you.

### RollingUpdate

If the deployment strategy is set to `RollingUpdate`, when kube-state-metrics is updated it is possible for there to be
two running instances for a short duration. This means that there shouldn't be a gap in metrics, but could lead to
duplicate metrics for a short duration.

### Recreate

However, if the deployment strategy is set to `Recreate`, the old kube-state-metrics pod is terminated before the new
one is started. This means that there will be a gap in metrics while the new pod is starting.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: sharded-kube-state-metrics

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

clusterMetrics:
  enabled: true
  kube-state-metrics:
    autosharding:
      enabled: true
    replicas: 5

alloy-metrics:
  enabled: true
```
<!-- textlint-enable terminology -->
