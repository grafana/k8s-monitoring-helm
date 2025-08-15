# Structure

The Kubernetes Monitoring Helm chart contains many software packages, and builds a comprehensive set of configuration
and secrets for those packages. Refer to
the [Helm chart documentation](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/)
to learn more.

## Charts

Features are stored in their own Helm chart in
the [charts folder](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts). Each feature
chart is not a standalone chart, but is included in the main k8s-monitoring Helm chart as a dependency. The parent chart
interacts with the feature chart via template functions.

To learn more, refer
to [Features documentation](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/#features).

## Collectors

Collectors in
the [collectors folder](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/collectors) are
Grafana Alloy instances deployed by the Alloy Operator as Kubernetes workloads.
To view the values and descriptions, refer
to [alloy](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/alloy.md).
To learn more, refer
to [Collectors reference documentation](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/collector-reference/).

## Examples

The [examples folder](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/examples)
contains full examples to guide you in configuring and customizing the Helm chart. To learn more, refer
to [Customize the Helm chart](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/customize-helm-chart/).

## Destinations

The [destinations folder](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/destinations)
contains examples and a values.yaml file for each destination. To learn more about destinations, refer
to [Destinations and proxies](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/customize-helm-chart/#destinations-and-proxies).

## Contributing

Use the following guidelines to contribute to the Helm chart.

### Features

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

Also refer to the [Contributing guide](./CONTRIBUTING.md).

### Documentation

To add a README.md for a feature:

1.  Within the examples directory, create a subfolder for the feature in the [features](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/examples/features) folder.
2.  Add a description text for the feature.
3.  Add a values.yaml file.
4.  Need your help here, Pete.

To add documentation to
the [Kubernetes Monitoring Helm chart docs](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/),
create an issue in this repository if you are not a Grafana employee.
