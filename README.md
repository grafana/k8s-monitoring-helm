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
| `metrics.kube_state_metrics.enable` | Install and scrape Kube State Metrics | `true` |
| `metrics.kube_state_metrics.allowList` | Only upload specified Kube State Metrics metrics to Grafana Cloud |  |
| `metrics.node_exporter.enable` | Install and scrape Node Exporter metrics | `true` |
| `metrics.node_exporter.allowList` | Only upload specified Node Exporter metrics to Grafana Cloud |  |
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

### Installing on OpenShift

```yaml
metrics:
  enable: true
  kube_state_metrics:
    enable: false
    TODO: some sort of way to discover KSM
  node_exporter:
    enable: false
    TODO: some sort of way to discover node exporter
```
