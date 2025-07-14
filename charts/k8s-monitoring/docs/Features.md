# Features

The Kubernetes Monitoring Helm chart contains multiple features to group common monitoring tasks into  sections within
the chart. Any feature contains the Alloy configuration used to discover, gather, process, and deliver the appropriate
telemetry data, as well as some additional Kubernetes workloads to supplement Alloy's functionality. Features can be
enabled with the `enabled` flag, and each contain multiple configuration options described in the feature's
documentation.

These are the current features supported in this Helm chart:

-   [Cluster Metrics](#cluster-metrics)
-   [Cluster Events](#cluster-events)
-   [Application Observability](#application-observability)
-   [Annotation Autodiscovery](#annotation-autodiscovery)
-   [Prometheus Operator Objects](#prometheus-operator-objects)
-   [Node Logs](#node-logs)
-   [Pod Logs](#pod-logs)
-   [Service Integrations](#service-integrations)
-   [Profiling](#profiling)
-   [Frontend Observability](#frontend-observability)

## Cluster Metrics

Collects metrics about the Kubernetes Cluster, including the control plane if configured to do so.
Refer to the [documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cluster-metrics) for more information.

## Cluster Events

Collects Kubernetes Cluster events from the Kubernetes API server.
Refer to the [documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cluster-events) for more information.

## Application Observability

Opens receivers to collect telemetry data from instrumented applications, including tail sampling when configured to do
so. Refer
to [documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability) for more information.

## Annotation Autodiscovery

Collects metrics from any Pod or Service that uses a specific annotation.
Refer to [documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-annotation-autodiscovery) for more information.

## Prometheus Operator Objects

Collects metrics from Prometheus Operator objects, such as PodMonitors and ServiceMonitors.
Refer to [documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-prometheus-operator-objects) for more information.

## Node Logs

Collects logs from Kubernetes Cluster Nodes.
Refer to [documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-node-logs) for more information.

## Pod Logs

Collects logs from Kubernetes Pods.
Refer to [documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-pod-logs) for more information.

## Service Integrations

Collects metrics and logs from a variety of popular services and integrations.
Refer to [documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-integrations) for more information.

## Profiling

Collect profiles using Pyroscope.
Refer to [documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-profiling) for more information.

## Contributing

Features are stored in their own Helm chart. That chart is not a standalone chart, but is included in the main
k8s-monitoring Helm chart as a dependency. The parent chart interacts with the feature chart via template functions.

To add a new feature, create a new Helm chart in the `charts` directory. The chart should have a `feature-` prefix in
its name. The following files are required for a feature chart:

-   `templates/_module.alloy.tpl` - This file should contain a template function named
    `feature.<feature-slug>.module` Creates an [Alloy module](https://grafana.com/docs/alloy/latest/get-started/modules/)
    that wraps the configuration for your feature, and exposes any of these arguments as appropriate:
    -   `metrics_destination` - Defines where scrape metrics should be delivered
    -   `logs_destination` - Defines where logs should be delivered
    -   `traces_destination` - Defines where traces should be delivered
    -   `profiles_destination` - Defines where profiles should be delivered

-   `templates/_notes.alloy.tpl` - This file should contain these template functions:
    -   `feature.<feature-slug>.notes.deployments` - Returns a list of workloads that will be
    deployed to the Kubernetes Cluster by the feature
    -   `feature.<feature-slug>.notes.task` - Returns a one-line summary of what this feature will do
    -   `feature.<feature-slug>.notes.actions` - Returns any prompts for the user to take additional
        action after deployment
    -   `feature.<feature-slug>.summary` - Returns a dictionary of settings that is used for self-reporting metrics
