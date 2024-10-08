<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Azure AKS

In certain Azure AKS cluster configurations, pods are restricted from accessing the Kubernetes API server when they are
not deployed in the `kube-system` namespace. By setting the `kubernetes.azure.com/set-kube-service-host-fqdn`
annotation, an admission controller already present in the cluster will set the correct configuration that will enable
those pods. Specifically, this is required for:

*   All Alloy instances, because they use the API server to discover telemetry targets, secrets, and configuration
*   kube-state-metrics, because it uses the API server to build metrics about the objects inside the cluster
*   OpenCost, because it uses the API server to build cost metrics about the objects inside the cluster

Without the annotation, API server requests will come with an empty response and shows with errors like this:

```text
/etc/alloy/config.alloy:756:1: Failed to build component: building component: Get https://172.25.0.1:443/api/v1/namespaces/default/secrets/prometheus-k8s-monitoring: EOF
```

For more information, see the [AKS documentation](https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress#required-outbound-network-rules-and-fqdns-for-aks-clusters)

## Values

```yaml
---
cluster:
  name: azure-aks-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push

clusterMetrics:
  enabled: true
  kube-state-metrics:
    podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}

clusterEvents:
  enabled: true

podLogs:
  enabled: true

alloy-metrics:
  enabled: true
  controller:
    podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}
alloy-singleton:
  enabled: true
  controller:
    podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}
alloy-logs:
  enabled: true
  controller:
    podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}
```
