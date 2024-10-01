# Features

These are the current features supported in this Helm chart:

-   [Cluster Metrics](#cluster-metrics)
-   [Cluster Events](#cluster-events)
-   [Application Observability](#application-observability)
-   [Annotation Autodisocvery](#annotation-autodiscovery)
-   [Prometheus Operator Objects](#prometheus-operator-objects)
-   [Pod Logs](#pod-logs)
-   [Service Integrations](#service-integrations)
-   [Profiling](#profiling)
-   [Frontend Observability](#frontend-observability)

## Cluster Metrics

[Documentation](https://github.com/grafana/grafana-telemetry-collector-helm/tree/main/charts/cluster-metrics)

Collects metrics about the Kubernetes cluster.

## Cluster Events

[Documentation](https://github.com/grafana/grafana-telemetry-collector-helm/tree/main/charts/cluster-events)

Collects Kubernetes Cluster events.

## Application Observability

[Documentation](https://github.com/grafana/grafana-telemetry-collector-helm/tree/main/charts/application-observability)

Open receivers to collect telemetry data from instrumented applications.

## Annotation Autodiscovery

[Documentation](https://github.com/grafana/grafana-telemetry-collector-helm/tree/main/charts/annotation-autodiscovery)

Collects metrics from Pods and Services that use a specific annotation.

## Prometheus Operator Objects

[Documentation](https://github.com/grafana/grafana-telemetry-collector-helm/tree/main/charts/prometheus-operator-objects)

Collects metrics from Prometheus Operator objects, like PodMonitors and ServiceMonitors.

## Pod Logs

[Documentation](https://github.com/grafana/grafana-telemetry-collector-helm/tree/main/charts/pod-logs)

Collects logs from Kubernetes Pods.

## Service Integrations

[Documentation](https://github.com/grafana/grafana-telemetry-collector-helm/tree/main/charts/integrations)

Collects metrics and logs from a variety of popular services and integrations.

## Profiling

[Documentation](https://github.com/grafana/grafana-telemetry-collector-helm/tree/main/charts/profiling)

Collect profiles using Pyroscope.

## Frontend Observability

[Documentation](https://github.com/grafana/grafana-telemetry-collector-helm/tree/main/charts/frontend-observability)

Open a Faro receiver to collect telemetry data from instrumented frontend applications.
