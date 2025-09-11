<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Private Datasource Connect

The Private Datasource Connect (PDC) feature enables the deployment and monitoring of the PDC Agent for Grafana Cloud observability within a Kubernetes cluster.

The PDC Agent creates secure tunnels to connect external data sources (like databases, APIs, or services running outside your Kubernetes cluster) to your Grafana Cloud instance through Private Data Source Connect.

## Overview

The Private Datasource Connect feature:

- **Deploys the PDC Agent**: Uses the official pdc-agent Helm chart as a dependency
- **Configures Metrics Collection**: Sets up Alloy to discover and scrape PDC Agent metrics
- **Provides Security**: Uses proper security contexts and non-root containers
- **Enables Monitoring**: Routes PDC Agent metrics to your chosen destinations
- **Validates Configuration**: Ensures required PDC connection settings are provided

## Required Setup

Before enabling this feature, you must:

1. **Create an Access Policy token** in your Grafana Cloud stack with appropriate permissions
2. **Create a Kubernetes secret** with the token (recommended for production):
   ```bash
   kubectl create secret generic pdc-token --from-literal=token=YOUR_ACCESS_POLICY_TOKEN
   ```

## Usage

### Basic Configuration

```yaml
privateDatasourceConnect:
  enabled: true
  pdc-agent:
    cluster: "prod-us-central-0"          # Your Hosted Grafana stack cluster
    hostedGrafanaId: "123456"            # Your Hosted Grafana stack ID
    tokenSecretName: "pdc-token"         # Kubernetes secret with Access Policy token
```

### Advanced Configuration

```yaml
privateDatasourceConnect:
  enabled: true
  destinations: ["prometheus"]  # Custom destination routing
 
  pdc-agent:
    # Required PDC connection settings
    cluster: "prod-us-central-0"
    hostedGrafanaId: "123456"
    tokenSecretName: "pdc-token"
   
    # Optional deployment settings
    replicaCount: 3
    image:
      repository: grafana/pdc-agent
      tag: "v1.2.3"
      pullPolicy: IfNotPresent
   
    metricsPort: 8090
    debug: false
   
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi
   
    # Security contexts (using chart defaults)
    podSecurityContext:
      runAsUser: 30000
      runAsGroup: 30000
      fsGroup: 30000
   
    securityContext:
      capabilities:
        drop: [ALL]
      runAsNonRoot: true
      privileged: false
      allowPrivilegeEscalation: false
   
    # Additional arguments for the PDC agent
    extraArgs: []
 
  # Feature-specific metric filtering
  metricsTuning:
    includeMetrics:
      - "pdc_.*"
      - "ssh_.*"
      - "go_.*"
    excludeMetrics:
      - ".*_debug_.*"
 
  # Custom relabeling rules
  extraDiscoveryRules: |
    rule {
      source_labels = ["__meta_kubernetes_pod_annotation_custom_label"]
      target_label = "custom_label"
    }
 
  extraMetricProcessingRules: |
    rule {
      source_labels = ["__name__"]
      regex = "pdc_ssh_connection_duration_seconds"
      target_label = "__tmp_connection_time"
    }
```

### Testing Configuration (Not Recommended for Production)

For testing purposes only, you can use an insecure token value:

```yaml
privateDatasourceConnect:
  enabled: true
  pdc-agent:
    cluster: "prod-us-central-0"
    hostedGrafanaId: "123456"
    insecureTokenValue: "your-access-policy-token-here"  # NOT for production!
```

## Configuration Reference

### Required Settings

The following settings are required when the feature is enabled:

- `pdc-agent.cluster`: The cluster where your Hosted Grafana stack is running
- `pdc-agent.hostedGrafanaId`: The numeric ID of your Hosted Grafana stack
- Authentication: Either `pdc-agent.tokenSecretName` OR `pdc-agent.insecureTokenValue`

### PDC Agent Configuration

All configuration under `pdc-agent.*` is passed directly to the PDC Agent Helm chart. See the [PDC Agent documentation](https://grafana.com/docs/grafana-cloud/connect-externally-hosted/private-data-source-connect/configure-pdc/) for complete configuration options.

### Metrics Collection

The feature automatically configures Alloy to:
- Discover PDC Agent pods using Kubernetes service discovery
- Scrape metrics from the `/metrics` endpoint on port 8090
- Apply custom relabeling rules if specified
- Route metrics to configured destinations

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `deployAsConfigMap` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

<!-- textlint-disable terminology -->
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| peterolivo | <peter.olivo@grafana.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-private-datasource-connect>
<!-- markdownlint-enable list-marker-space -->

## Requirements

| Repository | Name | Version |
|------------|------|---------|
|  | pdc-agent | 0.0.1 |
<!-- markdownlint-enable no-bare-urls -->
## Values

### PDC Agent

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| enabled | bool | `true` | Enable the PDC Agent deployment. |
| extraDiscoveryRules | string | `""` | Rule blocks to be added to the prometheus.scrape component for PDC Agent metrics. These relabeling rules are applied pre-scrape against the targets from service discovery. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.scrape/#rule-block)) |
| extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for PDC Agent. These relabeling rules are applied post-scrape against the metrics returned from the scraped target. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) |
| maxCacheSize | string | `nil` | Sets the max_cache_size for PDC Agent prometheus.relabel component. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) Overrides global.maxCacheSize |
| metricsTuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metricsTuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |
| namespace | string | `""` | Namespace to deploy the PDC Agent in. |
| scrapeInterval | string | 60s | The default interval between scraping targets. Overrides global.scrapeInterval |
| scrapeTimeout | string | 10s | The default timeout for scrape requests. |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pdc-agent.affinity | object | `{}` |  |
| pdc-agent.cluster | string | `""` | The cluster where your Hosted Grafana stack is running |
| pdc-agent.debug | bool | `false` | Enable debug logging for the agent |
| pdc-agent.extraArgs | list | `[]` | Extra arguments for the pdc-agent |
| pdc-agent.fullnameOverride | string | `""` |  |
| pdc-agent.hostedGrafanaId | string | `""` | The numeric ID of your Hosted Grafana stack |
| pdc-agent.image | object | `{"pullPolicy":"IfNotPresent","repository":"grafana/pdc-agent","tag":""}` | Container image configuration |
| pdc-agent.imagePullSecrets | list | `[]` | Secrets for pulling an image from a private repository |
| pdc-agent.insecureTokenValue | string | `""` | Insecure token value for testing purposes (not recommended for production) |
| pdc-agent.metricsPort | int | `8090` | The port where metrics are served from the pdc agent |
| pdc-agent.nameOverride | string | `""` | Override the chart name |
| pdc-agent.nodeSelector | object | `{}` | Node selector, tolerations, and affinity |
| pdc-agent.podLabels | object | `{}` | Pod labels |
| pdc-agent.podSecurityContext | object | `{"fsGroup":30000,"runAsGroup":30000,"runAsUser":30000}` | Pod security context |
| pdc-agent.replicaCount | int | `3` | This will set the replicaset count |
| pdc-agent.resources | object | `{"requests":{"cpu":"100m","memory":"256Mi"}}` | Resource limits and requests |
| pdc-agent.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"runAsNonRoot":true}` | Container security context |
| pdc-agent.tokenSecretName | string | `""` | Secret name containing the Access Policy token (expects key 'token') |
| pdc-agent.tolerations | list | `[]` |  |
