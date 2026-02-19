<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Telemetry Services

This contains additional telemetry services that can be deployed to the Kubernetes Cluster.

## Usage

```yaml
telemetryServices:
  node-exporter:
    deploy: true
  ...
```

([values](#values))

<!-- textlint-disable terminology -->
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/telemetry-services>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->
## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://opencost.github.io/opencost-helm-chart | opencost | 2.5.9 |
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 6.4.2 |
| https://prometheus-community.github.io/helm-charts | node-exporter(prometheus-node-exporter) | 4.51.1 |
| https://prometheus-community.github.io/helm-charts | windows-exporter(prometheus-windows-exporter) | 0.12.3 |
| https://sustainable-computing-io.github.io/kepler-helm-chart | kepler | 0.6.1 |
## Values

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |

### Kepler

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kepler.deploy | bool | `false` | Deploy Kepler. |

### kube-state-metrics

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-state-metrics.deploy | bool | `false` | Deploy kube-state-metrics. Set to false if your cluster already has kube-state-metrics deployed. |
| kube-state-metrics.metricLabelsAllowlist | list | `["nodes=[agentpool,alpha.eksctl.io/cluster-name,alpha.eksctl.io/nodegroup-name,beta.kubernetes.io/instance-type,cloud.google.com/gke-nodepool,cluster-name,ec2.amazonaws.com/Name,ec2.amazonaws.com/aws-autoscaling-groupName,ec2.amazonaws.com/aws-autoscaling-group-name,ec2.amazonaws.com/name,eks.amazonaws.com/nodegroup,k8s.io/cloud-provider-aws,karpenter.sh/nodepool,kubernetes.azure.com/cluster,kubernetes.io/arch,kubernetes.io/hostname,kubernetes.io/os,node.kubernetes.io/instance-type,topology.kubernetes.io/region,topology.kubernetes.io/zone]"]` | `kube_<resource>_labels` metrics to generate. The default is to include a useful set for Node labels. |

### Node Exporter

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| node-exporter.deploy | bool | `true` | Deploy Node Exporter. Set to false if your cluster already has Node Exporter deployed. |

### OpenCost

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| opencost.deploy | bool | `false` | Deploy OpenCost. |
| opencost.metricsSource | string | `""` | The name of the metric destination where OpenCost will query for required metrics. Setting this will enable guided setup for required OpenCost parameters. To skip guided setup, set this to "custom". |
| opencost.opencost.prometheus.existingSecretName | string | `""` | The name of the secret containing the username and password for the metrics service. This must be in the same namespace as the OpenCost deployment. |
| opencost.opencost.prometheus.external.url | string | `""` | The URL for Prometheus queries. It should match externalServices.prometheus.host + "/api/prom" |
| opencost.opencost.prometheus.password_key | string | `"password"` | The key for the password property in the secret. |
| opencost.opencost.prometheus.username_key | string | `"username"` | The key for the username property in the secret. |

### Windows Exporter - Deployment settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| windows-exporter.deploy | bool | `true` | Deploy Windows Exporter. Set to false if your cluster already has Windows Exporter deployed. |
