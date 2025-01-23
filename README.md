# Kubernetes Monitoring Helm Charts

<div align="center">

[![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?logo=grafana&logoColor=white)](https://grafana.com)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/grafana)](https://artifacthub.io/packages/search?org=grafana)
[![Helm Chart](https://img.shields.io/badge/helm-k8s--monitoring-blue?logo=helm)](https://img.shields.io/endpoint?url=https://artifacthub.io/packages/helm/grafana/k8s-monitoring)
![GitHub Release](https://img.shields.io/github/v/release/grafana/k8s-monitoring-helm)
![GitHub Release Date](https://img.shields.io/github/release-date/grafana/k8s-monitoring-helm)

[![Unit Tests](https://github.com/grafana/k8s-monitoring-helm/actions/workflows/unit-test.yml/badge.svg?branch=main)](https://github.com/grafana/k8s-monitoring-helm/actions/workflows/unit-test.yml?query=branch%3Amain)
[![Integration Tests](https://github.com/grafana/k8s-monitoring-helm/actions/workflows/integration-test.yml/badge.svg?branch=main)](https://github.com/grafana/k8s-monitoring-helm/actions/workflows/integration-test.yml?query=branch%3Amain)
[![Platform Tests](https://github.com/grafana/k8s-monitoring-helm/actions/workflows/platform-test.yml/badge.svg?branch=main)](https://github.com/grafana/k8s-monitoring-helm/actions/workflows/platform-test.yml?query=branch%3Amain)
![GitHub License](https://img.shields.io/github/license/grafana/k8s-monitoring-helm)

</div>

## Maintainers

| Name     | Email                         | URL |
|----------|-------------------------------|-----|
| petewall | <pete.wall@grafana.com>       |     |
| rlankfo  | <robert.lankford@grafana.com> |     |
| skl      | <stephen.lang@grafana.com>    |     |

## Usage

[Helm](https://helm.sh/) must be installed to use the chart. Please refer to
Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repository as follows:

```console
helm repo add grafana https://grafana.github.io/helm-charts
```

See
the [Chart Documentation](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring-v1/README.md)
for chart install instructions.

## Office Hours

We hold office hours roughly monthly. Meeting times and recordings will be posted here:

| Date       | Topic                       | Link                                                                           |
|------------|-----------------------------|--------------------------------------------------------------------------------|
| 2024-10-11 | Upcoming 2.0 version        | [Recording](https://youtu.be/2N6MQN45Gy8)                                      |
| 2024-11-22 | 2.0 Status                  | [Recording](https://youtu.be/rR6yxTEGLZc)                                      |
| 2024-12-19 | 2.0 Status and release date | [Recording](https://youtu.be/zkhR_5v1i9g)                                      |
| 2025-01-24 | 2.0 Release and future      | [Meeting Link](https://grafana.slack.com/archives/CAGMZG3GB/p1737059655740439) |

## Contributing

See our [Contributing Guide](./CONTRIBUTING.md) for more information.

## Links

-   [Kubernetes Monitoring on Grafana Cloud](https://grafana.com/docs/grafana-cloud/kubernetes-monitoring/)
-   [Grafana Alloy](https://github.com/grafana/alloy)
-   [Kube State Metrics](https://github.com/kubernetes/kube-state-metrics)
-   [Node Exporter](https://github.com/prometheus/node_exporter)
-   [OpenCost](https://github.com/opencost/opencost)
