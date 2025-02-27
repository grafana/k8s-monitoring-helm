# Testing

The Kubernetes Monitoring Helm chart includes a robust collection of tests that are designed to validate the chart's functionality and ensure that it is working as expected.

These tests are essential for maintaining the chart's reliability and ensuring that it continues to meet the needs of its users. There are three tiers of tests that are included in this Chart:

1.  Unit tests
2.  Integration tests
3.  Platform tests

You can run these tests from your own workstation to ensure that they pass before pushing your changes to the repository.

The unit and integration tests are also run automatically on every Pull Request and commits to the `main` branch.

## Unit Tests

Unit tests utilize the [helm unittest](https://github.com/helm-unittest/helm-unittest) plugin, and exercise the Helm chart at the template level. They are useful to evaluating that invidual sections of the chart are rendered correctly, especially under different configurations.

To run these tests, use the `make unittest` command.

## Integration Tests

Integration tests are end-to-end tests that exercise the chart as a whole. They use [kind](https://kind.sigs.k8s.io/) to create a local Kubernetes cluster and deploy the chart to it.

Each integration runs the following steps:

1.  Create a kind cluster.
2.  Deploy [Flux](https://fluxcd.io/) to the cluster.
3.  Apply the `deployments` directory to the cluster, which typically includes:
    -   Databases, depending on the telemetry data types being sent (e.g. Prometheus, Loki, Tempo, etc.)
    -   Grafana, pre-configured with those data sources enabled
    -   The k8s-monitoring-test Helm chart, which includes the test queries
4.  Deploy the k8s-monitoring Helm chart with the values.yaml file.
5.  Runs the k8s-monitoring-test chart's `helm test` command, which runs the queries against the databases and ensures that the results are as expected.

To run these tests, run the `run-cluster-test.sh` script with the test directory as the argument.

```bash
./scripts/run-cluster-test.sh charts/k8s-monitoring/tests/integration/cluster-monitoring
```

## Platform Tests

Platform tests are a variant of integration tests, but utilize external dependencies.

Some of the tests will provision a Kubernetes Cluster from cloud service providers, such as AWS and GCP. Clusters can be provisioned using various configurations, allows tests to check for platform specific behavior.

All of the tests utilize a Grafana Cloud instance for data storage, rather than deploying local databases.

The test directories are set up to use [direnv](https://direnv.net/) to manage the environment variables, including required credentials.

To run these tests, run `make run-test` from within the test directory.

```bash
cd charts/k8s-monitoring/tests/platform/gke-autopilot
direnv allow
make run-test
```

Due to the time and resource requirements of these tests, they are not run on every pull request. However, if the pull request includes the label `platform-test-<test name>`, that specific test will be run.

The full suite of platform tests are run before every release of the chart.
