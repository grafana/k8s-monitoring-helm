# Features

These are the current features supported in this Helm chart:

-   [Cluster Metrics](#cluster-metrics)
-   [Cluster Events](#cluster-events)
-   [Application Observability](#application-observability)
-   [Annotation Autodiscovery](#annotation-autodiscovery)
-   [Prometheus Operator Objects](#prometheus-operator-objects)
-   [Pod Logs](#pod-logs)
-   [Service Integrations](#service-integrations)
-   [Profiling](#profiling)
-   [Frontend Observability](#frontend-observability)

## Cluster Metrics

[Documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-cluster-metrics)

Collects metrics about the Kubernetes cluster.

## Cluster Events

[Documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-cluster-events)

Collects Kubernetes Cluster events.

## Application Observability

[Documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-application-observability)

Open receivers to collect telemetry data from instrumented applications.

## Annotation Autodiscovery

[Documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-annotation-autodiscovery)

Collects metrics from Pods and Services that use a specific annotation.

## Prometheus Operator Objects

[Documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-prometheus-operator-objects)

Collects metrics from Prometheus Operator objects, like PodMonitors and ServiceMonitors.

## Pod Logs

[Documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-pod-logs)

Collects logs from Kubernetes Pods.

## Service Integrations

[Documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-integrations)

Collects metrics and logs from a variety of popular services and integrations.

## Profiling

[Documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-profiling)

Collect profiles using Pyroscope.

## Contributing

Features are stored in their own Helm chart. That chart is not a standalone chart, but is included in the main
k8s-monitoring Helm chart as a dependency. The parent chart interacts with the feature chart via template functions.

To add a new feature, create a new Helm chart in the `charts` directory. The chart should have a `feature-` prefix in
its name. The following files are required for a feature chart:

-   `templates/_module.alloy.tpl` - This file should contain a template function named
    `feature.<feature-slug>.module` which should create an [Alloy module](https://grafana.com/docs/alloy/latest/get-started/modules/)
    that wraps the configuration for your feature. It should expose any of these arguments as appropriate:
    -   `metrics_destination` - An argument that defines where scrape metrics should be delivered.
    -   `logs_destination` - An argument that defines where logs should be delivered.
    -   `traces_destination` - An argument that defines where traces should be delivered.
    -   `profiles_destination` - An argument that defines where profiles should be delivered.

-   `templates/_notes.alloy.tpl` - This file should contain these template functions:
    -   `feature.<feature-slug>.notes.deployments` - This function returns a list of workloads that will be
    deployed to the Kubernetes Cluster by the feature.
    -   `feature.<feature-slug>.notes.task` - This function returns a 1-line summary of what this feature will do.
    -   `feature.<feature-slug>.notes.actions` - This function returns any prompts for the user to take additional
        action after deployment.
    -   `feature.<feature-slug>.summary` - This function a dictionary of settings, used for self-reporting metrics.
