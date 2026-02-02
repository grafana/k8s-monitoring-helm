# k8s-monitoring-helm AI Assistant Guide

This repository contains Helm charts for deploying Kubernetes monitoring to Grafana Cloud
or self-hosted Grafana stacks.

## For AI Assistants

**Start here:** [charts/k8s-monitoring/AGENTS.md](charts/k8s-monitoring/AGENTS.md)

This is where all configuration patterns and feature documentation lives. The chart-level
AGENTS.md contains discovery patterns, feature mappings, and examples for common tasks.

Key paths from repository root:

-   `charts/k8s-monitoring/values.yaml` - Main configuration file
-   `charts/k8s-monitoring/charts/feature-*/` - Feature subcharts (pod-logs, cluster-metrics, etc.)
-   `charts/k8s-monitoring/docs/examples/` - Complete example configurations

## For Chart Users

See [charts/k8s-monitoring/AGENTS.md](charts/k8s-monitoring/AGENTS.md) for help
configuring and deploying the k8s-monitoring Helm chart (v2).

Topics covered:

-   Chart architecture (features, collectors, destinations)
-   Configuration patterns and examples
-   Available features, integrations, and destinations

## For Contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

Additional resources:

-   [charts/k8s-monitoring/docs/Structure.md](charts/k8s-monitoring/docs/Structure.md) - How to add new features
-   [charts/k8s-monitoring/docs/create-a-new-feature/](charts/k8s-monitoring/docs/create-a-new-feature/) - Feature creation templates
