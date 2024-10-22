<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring-test

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)
A Helm chart for testing the Kubernetes Monitoring Helm chart

This chart is intended for testing the [k8s-monitoring](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring) chart.

It allows for a way to encode queries that will be used to ensure that telemetry data collected by the k8s-monitoring
chart is actually delivered to the desired destinations.

## Usage

To use this chart, specify a test:

```yaml
tests:
  - env:
      PROMETHEUS_URL: https://prometheus-server.prometheus.svc:9090/api/v1/query
      PROMETHEUS_USER: promuser
      PROMETHEUS_PASS: prometheuspassword
    queries:
      - query: kubernetes_build_info{cluster="cluster-monitoring-feature-test", job="integrations/kubernetes/kubelet"}
        type: promql
```

Each query will be run sequentially, and the test will fail if any of the queries return an error or does not have
the expected output.

In order to specify different destinations of the same type, you can use multiple tests:

```yaml
  - env:
      PROMETHEUS_URL: https://prometheus-one:9090/api/v1/query
      PROMETHEUS_USER: promuser-one
      PROMETHEUS_PASS: prometheuspassword-one
    queries:
      - query: kubernetes_build_info{color="blue"}
        type: promql
  - env:
      PROMETHEUS_URL: https://prometheus-two:9090/api/v1/query
      PROMETHEUS_USER: promuser-two
      PROMETHEUS_PASS: prometheuspassword-two
    queries:
      - query: kubernetes_build_info{color="green"}
        type: promql
```

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring-test>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Test settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| attempts | int | `10` | Number of times to retry the test on failure. |
| delay | int | `30` | Delay, in seconds, between test runs. |
| initialDelay | int | `0` | Initial delay, in seconds, before starting the first test run. |
| tests | list | `[]` | The tests to run. Each should contain an "env" object and a "queries" list. |

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |

### Image Registry

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.image.pullSecrets | list | `[]` | Optional set of global image pull secrets. |
| global.image.registry | string | `""` | Global image registry to use if it needs to be overridden for some specific use cases (e.g local registries, custom images, ...) |

### Image settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.pullSecrets | list | `[]` | Optional set of image pull secrets. |
| image.registry | string | `"ghcr.io"` | Test pod image registry. |
| image.repository | string | `"grafana/k8s-monitoring-test"` | Test pod image repository. |
| image.tag | string | `""` | Test pod image tag. Default is the chart version. |

### Job settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pod.extraAnnotations | object | `{}` | Extra annotations to add to the test runner pods. |
| pod.extraLabels | object | `{}` | Extra labels to add to the test runner pods. |
| pod.nodeSelector | object | `{"kubernetes.io/os":"linux"}` | nodeSelector to apply to the test runner pods. |
| pod.serviceAccount | object | `{"name":""}` | Service Account to use for the test runner pods. |
| pod.tolerations | list | `[]` | Tolerations to apply to the test runner pods. |
