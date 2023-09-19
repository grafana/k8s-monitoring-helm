# Examples

This directory contains example inputs and outputs for the Kubernetes Monitoring Helm chart.
These are real examples, not contrived text snippets. They use the chart itself to generate the outputs.

In each example, there is a values.yaml file, which serves as the input for the chart.
Then, `helm template` is used to render the chart to produce `output.yaml`, which is what would be deployed to the
Kubernetes cluster, given that values file.

Then, we extract the Grafana Agent configuration files from the ConfigMap objects and save them as `metrics.river` and
`logs.river`.

![Process for generating example files](process.png)

## Index of examples

* [Default values](./default-values) - The most basic example

### Enabling or disabling features

* [Logs Only](./logs-only) - Only gather and send logs
* [Metrics Only](./metrics-only) - Only scrape and send metrics
* [Traces Enabled](./traces-enabled) - Enable the OpenTelemetry receiver for traces and send then to Grafana Tempo
* [Windows Exporter](./windows-exporter) - Enable deployment and scraping of the Windows Exporter for Windows nodes

### Customizing behavior

* [Custom Allow Lists](./custom-allow-lists) - Change which metrics are send to Prometheus
* [Custom Configs](./custom-config) - Add arbitrary Grafana Agent Flow components to the configuration
* [Extra Rules](./extra-rules) - Add extra rules and stages for discovering and processing metrics and logs
* [Scrape Intervals](./scrape-intervals) - Customize how often to scrape metrics
* [Specific Namespace](./specific-namespace) - Only gather metrics and logs from workloads in specific namespaces

### Specific platform examples

* [OpenShift Compatible](./openshift-compatible) - What changes from the default to deploy successfully to OpenShift
