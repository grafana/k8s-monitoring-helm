# Kubernetes Monitoring Helm Chart

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

## Why use this chart?

There are many great Helm charts for individual pieces of the observability stack:
[Grafana Alloy](https://github.com/grafana/alloy), the OpenTelemetry
[Collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) and
[Operator](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator),
[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts),
[kube-state-metrics](https://github.com/kubernetes/kube-state-metrics),
[Node Exporter](https://github.com/prometheus/node_exporter), and more. Each is excellent at its job, but wiring them
together into a complete, correct, and consistent monitoring solution can be a significant amount of work.

This chart exists to do that wiring for you. Instead of assembling and maintaining a collection of separate charts, you
describe *what* you want to monitor and *where* it should go, and the chart generates the collector configuration and
deploys the supporting components to make it happen.

-   **One chart for all telemetry signals.** Metrics, logs & events, traces and profiles are all covered by a single,
    coordinated deployment rather than a patchwork of charts that have to be kept in sync.

-   **Feature-oriented configuration, not collector plumbing.** The chart is organized into features that enable
    telemetry gathering based on outcomes like node and cluster metrics, node and pod logs, application observability,
    auto-instrumentation and more. The chart translates those choices into the underlying collector configuration, so
    there is no need to hand-write and debug collector pipelines.

-   **Pluggable destinations.** Send data to Grafana Cloud or to any Prometheus-, Loki-, OTLP-, or Pyroscope-compatible
    backend. The same configuration can fan out to multiple destinations at once, and switching backends is a
    configuration change rather than a re-architecture.

-   **Collection only, no bundled database.** Unlike all-in-one charts such as kube-prometheus-stack, this chart does
    not deploy a storage backend, Grafana, or Alertmanager. It focuses solely on collecting and shipping telemetry to
    the destination of your choice, which keeps it lightweight yet scalable enough for testing, development, and
    production environments.

-   **Batteries included, but not required.** Supplemental components such as kube-state-metrics, Node Exporter, Windows
    Exporter, and OpenCost are deployed and pre-wired when the relevant features are enabled.

-   **Opinionated, curated defaults.** Sensible scrape configs, relabeling, and metric tuning come out of the box to
    keep cardinality and cost under control, while still allowing for overrides.

-   **Validated and tested.** The generated configuration is validated at render time to catch mistakes early, and the
    chart is exercised by extensive unit, integration, and platform test suites across Kubernetes distributions.

If you only need one signal from one component, a single-purpose chart may be all you need. If you want a complete
monitoring solution on Kubernetes that ties those components together and sends everything to the backend of your
choice, this chart is built for that.

## Maintainers

| Name         | Email                         | URL |
|--------------|-------------------------------|-----|
| petewall     | <pete.wall@grafana.com>       |     |
| rlankfo      | <robert.lankford@grafana.com> |     |
| TylerHelmuth | <tyler.helmuth@grafana.com>   |     |

## Usage

[Helm](https://helm.sh/) must be installed to use the chart. Please refer to
Helm's [documentation](https://helm.sh/docs/) to get started.

### Install from the Helm repository

```console
helm repo add grafana https://grafana.github.io/helm-charts
helm install k8s-monitoring grafana/k8s-monitoring --values values.yaml
```

### Install from the OCI registry

```console
helm install k8s-monitoring oci://ghcr.io/grafana/helm-charts/k8s-monitoring --values values.yaml
```

Refer to the [Chart Documentation](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/)
to learn more, including about chart installation instructions.

## Office Hours

We hold office hours on the 4th Friday of the month. Meeting times and recordings will be posted here:

| Date       | Topic                                         | Link                                          |
|------------|-----------------------------------------------|-----------------------------------------------|
| 2026-09-25 | TBD                                           | [Zoom](https://grafana.zoom.us/j/96633896206) |
| 2026-08-28 | 4.4 and 4.5 Releases                          | [Recording](https://youtu.be/8G6hkGP1Apo)     |
| 2026-07-24 | 4.2 and 4.3 Releases                          | [Recording](https://youtu.be/qUPHXTrZrJo)     |
| 2026-06-29 | 4.1 and 4.2 Releases                          | [Recording](https://youtu.be/QvgHm7VU2mA)     |
| 2026-05-29 | 4.1 and 4.2 Releases                          | [Recording](https://youtu.be/sIu7BLNRVJA)     |
| 2026-04-28 | 4.1 Release                                   | [Recording](https://youtu.be/XC2VNKd57YU)     |
| 2026-03-27 | 4.0 Release                                   | [Recording](https://youtu.be/lgYNFkzREsA)     |
| 2026-02-27 | 3.8 Release and 4.0 preview                   | [Recording](https://youtu.be/OquS3vMaGNE)     |
| 2026-01-23 | 3.7 Release                                   | [Recording](https://youtu.be/VyqreBQuVtM)     |
| 2025-12-12 | 3.6 Release                                   | [Recording](https://youtu.be/T-EaHzJ1Qbs)     |
| 2025-10-24 | 3.6 Release preview                           | [Recording](https://youtu.be/z3BNfJLWBj4)     |
| 2025-09-26 | 3.4 & 3.5 Releases                            | [Recording](https://youtu.be/7V7NKY1NAqE)     |
| 2025-08-22 | 3.3 Release                                   | [Recording](https://youtu.be/GPverf9LpIo)     |
| 2025-07-25 | 3.2 Release                                   | [Recording](https://youtu.be/pEj6pgHev6E)     |
| 2025-06-27 | 2.1 --> 3.0 Re-Version and 3.1 Release        | [Recording](https://youtu.be/2fUoady4lu0)     |
| 2025-05-27 | 2.1 Release                                   | [Recording](https://youtu.be/12_7y9_EdTI)     |
| 2025-04-25 | 2.1 Release update                            | [Recording](https://youtu.be/prFhW_vOR2w)     |
| 2025-02-28 | 2.1 Release update and K8s Monitoring Product | [Recording](https://youtu.be/bWiDdHSWhiI)     |
| 2025-01-24 | 2.0 Release and future                        | [Recording](https://youtu.be/-cNnXO1AGOk)     |
| 2024-12-19 | 2.0 Status and release date                   | [Recording](https://youtu.be/zkhR_5v1i9g)     |
| 2024-11-22 | 2.0 Status                                    | [Recording](https://youtu.be/rR6yxTEGLZc)     |
| 2024-10-11 | Upcoming 2.0 version                          | [Recording](https://youtu.be/2N6MQN45Gy8)     |

## Contributing

See our [Contributing Guide](./CONTRIBUTING.md) for more information.

## Links

-   [Kubernetes Monitoring on Grafana Cloud](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/intro-kubernetes-monitoring/)
-   [Grafana Alloy](https://github.com/grafana/alloy)
-   [Kube State Metrics](https://github.com/kubernetes/kube-state-metrics)
-   [Node Exporter](https://github.com/prometheus/node_exporter)
-   [OpenCost](https://github.com/opencost/opencost)
