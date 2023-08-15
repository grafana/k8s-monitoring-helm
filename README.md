# Kubernetes Monitoring Helm Charts

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
| skl | <stephen.lang@grafana.com> |  |

## Usage

[Helm](https://helm.sh/) must be installed to use the chart. Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add grafana https://grafana.github.io/helm-charts
```

See the [Chart Documentation](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/README.md) for chart install instructions.

## Contributing

We welcome contributions and improvements! Feel free to submit PRs.

If you make changes to this chart, please ensure that you've done the following:

* Update the chart version
* Use [Helm Docs](https://github.com/norwoodj/helm-docs) to check for updates to the chart documentation
  * `cd charts/k8s-monitoring; helm-docs`
* Check for updates to the example outputs
  * `make test`
  * If changes are acceptable, regenerate the outputs:
  * `make regenerate-example-outputs`

Required tools:

* [chart-testing](https://github.com/helm/chart-testing)
* [Helm](https://helm.sh/docs/intro/install/)
* [helm-docs](https://github.com/norwoodj/helm-docs)
* [Grafana Agent](https://github.com/grafana/agent) (used for linting the generated config files)
* [yamllint](https://yamllint.readthedocs.io/en/stable/index.html)
* [yq](https://pypi.org/project/yq/)

## Links
* [Kubernetes Monitoring on Grafana Cloud](https://grafana.com/docs/grafana-cloud/kubernetes-monitoring/)
* [Grafana Agent](https://github.com/grafana/agent)
* [Kube State Metrics](https://github.com/kubernetes/kube-state-metrics)
* [Node Exporter](https://github.com/prometheus/node_exporter)
* [OpenCost](https://github.com/opencost/opencost)
