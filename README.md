# Kubernetes Monitoring Helm Charts

<div align="center">

[![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?logo=grafana&logoColor=white)](https://grafana.com)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/grafana)](https://artifacthub.io/packages/search?org=grafana)
[![Helm Chart](https://img.shields.io/badge/helm-k8s--monitoring-blue?logo=helm)](https://img.shields.io/endpoint?url=https://artifacthub.io/packages/helm/grafana/k8s-monitoring)
![GitHub Release](https://img.shields.io/github/v/release/grafana/k8s-monitoring-helm)
![GitHub Release Date](https://img.shields.io/github/release-date/grafana/k8s-monitoring-helm)

[![Test Charts](https://github.com/grafana/k8s-monitoring-helm/workflows/Test/badge.svg?branch=main)](https://github.com/grafana/k8s-monitoring-helm/actions/workflows/helm-test.yml?query=branch%3Amain)
[![Release Charts](https://github.com/grafana/k8s-monitoring-helm/workflows/Release%20Helm%20chart/badge.svg?branch=main)](https://github.com/grafana/k8s-monitoring-helm/actions/workflows/helm-release.yml?query=branch%3Amain)
![GitHub License](https://img.shields.io/github/license/grafana/k8s-monitoring-helm)

</div>

## Maintainers

| Name | Email | URL |
| ---- | ------ |-----|
| petewall | <pete.wall@grafana.com> |     |
| skl | <stephen.lang@grafana.com> |     |

## Usage

[Helm](https://helm.sh/) must be installed to use the chart. Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repository as follows:

```console
helm repo add grafana https://grafana.github.io/helm-charts
```

See the [Chart Documentation](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/README.md) for chart install instructions.

## Contributing

See our [Contributing Guide](./CONTRIBUTING.md) for more information.

## Links

-   [Kubernetes Monitoring on Grafana Cloud](https://grafana.com/docs/grafana-cloud/kubernetes-monitoring/)
-   [Grafana Alloy](https://github.com/grafana/alloy)
-   [Kube State Metrics](https://github.com/kubernetes/kube-state-metrics)
-   [Node Exporter](https://github.com/prometheus/node_exporter)
-   [OpenCost](https://github.com/opencost/opencost)
