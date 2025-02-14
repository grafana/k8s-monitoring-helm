# Contributing

We welcome contributions and improvements! Feel free to submit PRs.

The process for making a successful contribution is:

1.  Make your change
2.  Build any generated files: `make build`
3.  Run unit tests: `make test`
4.  Create your PR!
5.  Wait for checks to pass
    -   Lint checks
    -   Unit tests
    -   Integration tests

## Design Idioms

The Kubernetes Monitoring Helm chart has a few design idioms with the goal of making it an easy and pleasant experience
for users and maintainers. These should guide your contributions:

### Don't ask about systems, ask about outcomes

Many users will not know about the particular observability systems and why one is better than another. Instead of
asking if they want to deploy a particular system, ask what outcome they want.

Bad:

```yaml
mega-widget:
  enabled: true
  megaQuarkMode: blue
```

Good:

```yaml
quantumObservability:
  enabled: true
  quarkMode: blue
```

### No error messages without suggestions

If a user encounters an error, we want to provide them with a suggestion for how to fix it.

Bad:

```text
Error: megaQuarkMode not set!
```

Good:

```text
Error: The Quantum Observability feature requires a quark mode!
Please set:
quantumObservability:
  quarkMode: <favorite color>
```

### Don't require the user to know configuration language

This Helm chart is essentially a package of observability collection systems and a utility to generate configurations
for those systems. It should be possible for a user to modify that configuration without needing to know the
actual config language syntax.

Bad:

```yaml
quantumObservability:
  extraDiscoveryRules: |
    // Keep only the production namespace
    rule {
      source_labels = ["__meta_kubernetes_namespace"]
      regex = "production"
      action = keep
    }
```

Good:

```text
quantumObservability:
  namespaces: [production]
```

### Lots of test automation

We want to make it easy to contribute to this project. We have a lot of test automation to ensure that changes are high
quality and robust.

### Just the right amount of magic

This is a bit hard to qualify, but using this chart should be simple and easy with predictable and intuitive defaults.
Sometimes, going too far with this can lead to a chart that does things that are unexpected.

No magic:

```yaml
quantumObservability:
  extraQuarkLabellingRules: ""
```

Some magic:

```yaml
quantumObservability:
  # Add quark labels from Kubernetes pod labels
  quarkLabelsFromPodLabels: {}
```

More magic:

```yaml
quantumObservability:
  # Add quark labels from Kubernetes pod labels
  quarkLabelsFromPodLabels:
    position: app.kubernetes.io/position
```

Too much magic:

```yaml
quantumObservability:
  # This will automatically add `position` from the `app.kubernetes.io/position` label
  quarkLabelsFromPodLabels: {}
```

## Tools

This repository heavily makes use of automation and tooling to generate files and run tests. The following tools are
required to work on this repository:

-   [Helm](https://helm.sh/docs/intro/install/)
-   [Docker](https://docs.docker.com/get-docker/) - Used for running some tools in containers and required for `kind`.
-   [chart-testing](https://github.com/helm/chart-testing) - Used for linting Helm charts.
-   [kind](https://kind.sigs.k8s.io/) - Used for creating local Kubernetes clusters for integration testing.
-   [Grafana Alloy](https://github.com/grafana/alloy) - Used for linting the generated config files.
-   [yamllint](https://yamllint.readthedocs.io/en/stable/index.html) - Used for linting YAML files.

Some tools are optional. If they are not present on your system, the equivalent Docker image will be run. Consider
installing them for a better experience:

-   [helm-docs](https://github.com/norwoodj/helm-docs) - Used for generating Helm chart README.md files.
-   [helm unittest](https://github.com/helm-unittest/helm-unittest) - Used for executing Helm chart unit tests.
-   [Flux CLI](https://fluxcd.io/flux/cmd/) - Used for executing Helm chart integration and platform tests.
-   [shellspec](https://github.com/shellspec/shellspec) - Used for executing some unit tests.
-   [vendir](https://carvel.dev/vendir/) - Used for downloading Alloy Module

If you are going to be running platform tests, you might want to install the following tools:

-   [gcloud](https://cloud.google.com/sdk/docs/install) - Used for interacting with Google Cloud Platform.
-   [aws-cli & eksctl](https://docs.aws.amazon.com/eks/latest/userguide/setting-up.html) - Used for interacting with Amazon Web Services and creating EKS clusters.
-   [az](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) - Used for interacting with Azure.
-   openshift-install - Used for creating OKD OpenShift clusters.
    -   `gh release download --repo okd-project/okd -p "openshift-install-mac-arm64*"`

Each chart has a Makefile with targets to automate much of the process.

## Contributor Guides

Each component has its own guide for contributing:

<!-- [Main Helm chart](./charts/k8s-monitoring/README.md#Contributing) -->

-   [Feature subcharts](./charts/k8s-monitoring/docs/Features.md#Contributing)
-   [Integrations](charts/k8s-monitoring/charts/feature-integrations/README.md#Contributing)
-   [Destinations](./charts/k8s-monitoring/docs/destinations/README.md#Contributing)

## Building

Lots of files in this repository are generated in order to reduce duplication and ensure consistency. To build these
files, run `make build`.

You can also run `make build` from inside the specific Chart directory to build only the files for that Chart.

These files are generated and any changes should be included in your PR:

-   `README.md` - The README file for the chart, this is generated from the values.yaml file.
-   `CHART.lock` - The lock file for the chart dependencies, this is generated from the Chart.yaml file.
-   `values.schema.json` - The JSON schema for the values.yaml file, this is generated from the values.yaml file and any
  modification files found in the `schema-mods` directories.
-   `docs/examples` - The examples directory contains usage examples that are rendered from the chart. This works in
  the `k8s-monitoring` and `k8s-monitoring-v1` charts.

Some charts will also generate additional templates and docs based on other files. For example, the
`feature-integrations` chart creates docs and templates based on each supported integration's own values.yaml file.

### Updating chart dependencies

If your chart is dependent on external charts, you can update the dependencies by:

1.  Set the dependency's version in Chart.yaml.
2.  Update the Chart.lock file by running `make -C charts/<the chart you are modifying> build`.

### Updating feature dependencies

If you made a change to a feature Helm chart, you'll also need to update the main `k8s-monitoring` Helm chart to include
your changes. To do this, run the following command:

```bash
rm charts/k8s-monitoring/Chart.lock
make -C charts/k8s-monitoring build
```

Include the modified chart bundles and Chart.lock file in your PR.

## Testing

Each chart contains unit tests and some contain integration tests. Unit tests run quickly and test parts of the chart
that don't require a Kubernetes cluster. Integration tests require a Kubernetes cluster and test the chart in a real
environment with dependencies.

### Unit tests

Unit tests can be run with `make test`. You can also run `make test` from inside the specific Chart directory to run
only the tests for that Chart.

### Integration tests

Integration tests run with a Kubernetes Cluster. The process for running the test is different for the v1 and v2 charts.

### `k8s-monitoring-v1` integration tests

To run the integration tests for the `k8s-monitoring-v1` chart, use the `setup-local-test-cluster.sh` script to build a
Kubernetes cluster using kind and deploy the telemetry data sources, data stores and Grafana. If you provide a values
file as an argument to that script (i.e. `setup-local-test-cluster.sh values.yaml`), it installs the k8s-monitoring Helm'
chart and runs helm test as well.

### `k8s-monitoring` integration tests

To run the integration tests for the `k8s-monitoring` chart, use the following commands:

```bash
./scripts/run-cluster-test.sh charts/k8s-monitoring/tests/integration/<test dir>
```

This will create a new Kubernetes cluster using kind, deploy any required dependencies, deploy the `k8s-monitoring` Helm
chart, and deploy the `k8s-monitoring-test` chart which contains the tests.

You can modify the behavior of the test by setting environment variables:

-   `DELETE_CLUSTER` - If set to `false`, the cluster will not be deleted after the test completes.
-   `CREATE_CLUSTER` - If set to `false`, the script will not create a new cluster, but will use whatever cluster your
  kubectl is configured to use.
-   `DEPLOY_GRAFANA` - If set to `false`, the script will not deploy Grafana. Grafana is only deployed to make debugging
  easier, because it will be pre-configured to connect to the database instances.

## Creating new releases

Creating new releases is typically only done by maintainers, most often Grafana Labs employees.

The process for creating a new release is:

1.  Update the chart version and push to main
2.  Ensure the CI tests on main are successful
3.  Run the appropriate release GitHub Action workflow.

### Updating the chart version

Use the [set-version.sh](./charts/k8s-monitoring-v1/scripts/set-version.sh) script to update the version and regenerate
the files that contain version numbers. For example:

```bash
% ./scripts/set-version.sh 1.2.3
```

This will also set the App Version to the latest release of
the [Kubernetes Monitoring](https://grafana.com/solutions/kubernetes/) in Grafana Cloud. If you do not have access to
that GitHub repository, you can set the App version in the second argument to the set-version.sh script. For example:

```bash
% ./scripts/set-version.sh 1.2.3 3.1.2
```

### Starting the release workflow

The [helm-release-v1.yml](./.github/workflows/helm-release-v1.yml) GitHub workflow handles the details of packaging the
v1 Chart, creating the release on this repository, creating a release on
the [grafana/helm-charts](https://github.com/grafana/helm-charts) repository, and finally updating the Helm chart
repository.
