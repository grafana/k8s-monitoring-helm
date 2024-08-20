# Azure AKS

In certain Azure AKS cluster configurations, pods are restricted from accessing the Kubernetes API server when they are
not deployed in the `kube-system` namespace. By setting the `kubernetes.azure.com/set-kube-service-host-fqdn`
annotation, an admission controller already present in the cluster will set the correct configuration that will enable
those pods. Specifically, this is required for:

* All Alloy instances, because they use the API server to discover telemetry targets, secrets, and configuration
* kube-state-metrics, because it uses the API server to build metrics about the objects inside the cluster
* OpenCost, because it uses the API server to build cost metrics about the objects inside the cluster

Without the annotation, API server requests will come with an empty response and shows with errors like this:

```text
/etc/alloy/config.alloy:756:1: Failed to build component: building component: Get https://172.25.0.1:443/api/v1/namespaces/default/secrets/prometheus-k8s-monitoring: EOF
```

For more information, see this documentation: https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress#required-outbound-network-rules-and-fqdns-for-aks-clusters

```yaml
---
cluster:
  name: aks-test

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

kube-state-metrics:
  podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}

opencost:
  podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}

alloy:
  controller:
    podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}
alloy-events:
  controller:
    podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}
alloy-logs:
  controller:
    podAnnotations: {kubernetes.azure.com/set-kube-service-host-fqdn: "true"}
```
