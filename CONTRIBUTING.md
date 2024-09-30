# Contributing

We welcome contributions and improvements! Feel free to submit PRs.

The [examples](charts/k8s-monitoring-v1/docs/examples) directory contains examples of using this Helm chart, and are built from the current state
of the chart. When you make changes, they will likely involve changes to some of those examples.

Required tools:

-   [chart-testing](https://github.com/helm/chart-testing)
-   [Helm](https://helm.sh/docs/intro/install/)
-   [helm-docs](https://github.com/norwoodj/helm-docs)
-   [kind](https://kind.sigs.k8s.io/)
-   [Grafana Alloy](https://github.com/grafana/alloy) (used for linting the generated config files)
-   [shellspec](https://github.com/shellspec/shellspec)
-   [yamllint](https://yamllint.readthedocs.io/en/stable/index.html)
-   [yq](https://github.com/mikefarah/yq/)

Run `make install-deps` to install all requirements (Mac supported only at the moment using Brew).

## Building generated files

After you have made your changes, ensure that you build the automatically generated files in this chart, by doing the
following:

-   Use [Helm Docs](https://github.com/norwoodj/helm-docs) to check for updates to the chart documentation
    -   `helm-docs` OR `cd charts/k8s-monitoring-v1 make README.md`
-   Check for updates to the example outputs
    -   `make test`
    -   If changes are acceptable, regenerate the outputs and re-test:
    -   `make regenerate-example-outputs test`

## Bumping Dependent Chart Versions

Chart dependencies are automatically updated via PRs, but if you want to manually set a chart dependency version:

-   Set the dependency's version in [Chart.yaml](charts/k8s-monitoring-v1/Chart.yaml).
-   Update the Chart.lock file by running `cd charts/k8s-monitoring-v1 helm dependency update`
-   Follow the steps above in [Building generated files](#building-generated-files) to update the examples and docs.
-   Finally, take a moment to inspect the generated output for anything that might cause trouble.

## Testing

You can test your changes with a similar platform to what is used in the CI/CD pipelines.

To build the cluster, use the [setup-local-test-cluster.sh](charts/k8s-monitoring-v1/test/setup-local-test-cluster.sh) script to build a
Kubernetes cluster using [kind](https://kind.sigs.k8s.io/) and deploy the telemetry data sources, data stores and
Grafana. If you provide a values file as an argument to that script (i.e. `setup-local-test-cluster.sh values.yaml`), it
installs the k8s-monitoring Helm chart and runs `helm test` as well.

## Creating new releases

Creating new releases is typically only done by maintainers, most often Grafana Labs employees.

The process for creating a new release is:

1.  Update the chart version and push to main
2.  Ensure the CI tests on main are successful
3.  Run [release.sh](./scripts/release.sh) to start the Release workflow.

### Updating the chart version

Use the [set-version.sh](./scripts/set-version.sh) script to update the version and regenerate the files that contain
version numbers. For example:

```bash
% ./scripts/set-version.sh 1.2.3
```

This will also set the App Version to the latest release of
the [Kubernetes Monitoring](https://grafana.com/solutions/kubernetes/) in Grafana Cloud. If you do not have access to
the GitHub repository, you can set the App version in the second argument to the set-version.sh script. For example:

```bash
% ./scripts/set-version.sh 1.2.3 3.1.2
```

### Starting the release workflow

The [helm-release.yml](./.github/workflows/helm-release-v1.yml) GitHub workflow handles the details of packaging the Chart,
creating the release on this repository, creating a release on
the [grafana/helm-charts](https://github.com/grafana/helm-charts) repository, and finally updating the Helm chart
repository.
