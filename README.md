# Kubernetes Monitoring Chart

This Helm chart simplifies the process of deploying a complete Kubernetes metrics gathering and exporting stack.

## Configuration

| Parameter | Description | Default |
|-|-|-|
| `cluster.name` | The name for this cluster | `my-cluster` |
| `metrics.enable` | Send metrics to Grafana Cloud | `true` |
| `metrics.prometheus.host` | The Prometheus to send metrics to | |
| `metrics.prometheus.username` | |
| `metrics.prometheus.password` | |
| `metrics.kube-state-metrics.enable` | Install and scrape Kube State Metrics | `true` |
| `metrics.kube-state-metrics.allowList` | Only upload specified Kube State Metrics metrics to Grafana Cloud |  |
| `metrics.kube-state-metrics.service.port` | The name of the metrics port for Kube State Metrics | `http` |
| `metrics.kube-state-metrics.service.isTLS` | Is this service using TLS | `false` |
| `metrics.node-exporter.enable` | Install and scrape Node Exporter metrics | `true` |
| `metrics.node-exporter.allowList` | Only upload specified Node Exporter metrics to Grafana Cloud |  |
| `metrics.node-exporter.service.port` | The name of the metrics port for Node Exporter | `http` |
| `metrics.node-exporter.service.isTLS` | Is this service using TLS | `false` |
| `metrics.kubelet.enable` | Install and scrape Kubelet metrics | `true` |
| `metrics.kubelet.allowList` | Only upload specified Kubelet metrics to Grafana Cloud |  |
| `metrics.cadvisor.enable` | Install and scrape cAdvisor metrics | `true` |
| `metrics.cadvisor.allowList` | Only upload specified cAdvisor metrics to Grafana Cloud |  |
| `metrics.cost.enable` | Install and scrape OpenCost metrics | `true` |
| `metrics.cost.allowList` | Only upload specified OpenCost metrics to Grafana Cloud |  |
| `logs.enable` | Send logs to Grafana Cloud | `true` |
| `logs.loki.host` | The Loki to send logs to | |
| `logs.loki.username` | |
| `logs.loki.password` | |
| `logs.pod_logs.enable` | Scrape pod logs | `true` |
| `logs.cluster_events.enable` | Scrape cluster events | `true` |
| `extraConfig` | Additional configuration that will be added to the Grafana Agent | |
| `kube-state-metrics.enable` | Should Kube State Metrics be deployed with this Helm chart | `true` |
| `node-exporter.enable` | Should Node Exporter be deployed with this Helm chart | `true` |
| `opencost.enable` | Should OpenCost be deployed with this Helm chart | `true` |
| `opencost.opencost.prometheus.external.url` | The URL for the Prometheus where metrics can be queried | `true` |


### Installing on OpenShift

```yaml
metrics:
  enable: true
  kube-state-metrics:
    deploy: false
    service:
      port: "8443"
      isTLS: true
  node-exporter:
    deploy: false
    TODO: some sort of way to discover node exporter
```
