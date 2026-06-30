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
| TylerHelmuth | <tyler.helmuth@grafana.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/telemetry-services>
<!-- markdownlint-enable list-marker-space -->
## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://grafana.github.io/helm-charts | beyla | 1.16.8 |
| https://grafana.github.io/helm-charts | k8s-manifest-tail(k8s-manifest-tail) | 0.1.5 |
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 7.5.1 |
| https://prometheus-community.github.io/helm-charts | node-exporter(prometheus-node-exporter) | 4.55.0 |
| https://prometheus-community.github.io/helm-charts | windows-exporter(prometheus-windows-exporter) | 0.12.7 |
| https://sustainable-computing-io.github.io/kepler-helm-chart | kepler | 0.6.1 |
| oci://ghcr.io/opencost/charts | opencost | 2.5.25 |
<!-- markdownlint-enable no-bare-urls -->
## Values

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.platform | string | `""` | The specific platform for this cluster. Will enable compatibility for some platforms. Supported options: (empty) or "openshift". |

### k8s-manifest-tail

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| k8s-manifest-tail.deploy | bool | `false` | Deploy k8s-manifest-tail to watch and log Kubernetes manifest changes. |
| k8s-manifest-tail.extraEnv | list | `[]` | Extra environment variables, required for setting the OTLP destination for the manifests. |

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
| node-exporter.portConflictCheck | bool | `true` | Check for an existing Node Exporter using the same port before deploying. If a conflict is detected, the install fails with guidance to use the existing Node Exporter or pick a unique port. Set to false to skip the check. |

### OpenCost

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| opencost.deploy | bool | `false` | Deploy OpenCost. |
| opencost.extraVolumes | list | `[{"emptyDir":{},"name":"configs"}]` | On GCP/GKE, OpenCost's GCP provider writes ${CONFIG_PATH}/gcp.json on startup. CONFIG_PATH defaults to /var/configs, which is not writable by the non-root container user, causing the pod to panic. Mount an emptyDir there so the default path is writable. This is preferred over setting CONFIG_PATH via extraEnv, which collides with the CONFIG_PATH the OpenCost chart sets when customPricing is enabled (duplicate env var). The upstream chart only mounts at /var/configs when cloud integration is enabled, so this does not conflict by default. |
| opencost.metricsSource | string | `""` | The name of the metric destination where OpenCost will query for required metrics. Setting this will enable guided setup for required OpenCost parameters. To skip guided setup, set this to "custom". |
| opencost.opencost.prometheus.existingSecretName | string | `""` | The name of the secret containing the username and password for the metrics service. This must be in the same namespace as the OpenCost deployment. |
| opencost.opencost.prometheus.external.url | string | `""` | The URL where OpenCost queries for the metrics it needs. Required when `metricsSource` is set to a metrics destination: the guided setup fails the install with the exact URL to use if this is left empty. It should point at the query endpoint of the destination named by `metricsSource` (e.g. that destination's URL with the remote-write path replaced by the query path, such as `/api/prom` or `/api/v1/query`). |
| opencost.opencost.prometheus.password_key | string | `"password"` | The key for the password property in the secret. |
| opencost.opencost.prometheus.username_key | string | `"username"` | The key for the username property in the secret. |

### Windows Exporter - Deployment settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| windows-exporter.deploy | bool | `true` | Deploy Windows Exporter. Set to false if your cluster already has Windows Exporter deployed. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| beyla.config.create | bool | `false` |  |
| beyla.config.skipConfigMapCheck | bool | `true` |  |
| beyla.enabled | bool | `false` |  |
| beyla.k8sCache.replicas | int | `0` |  |
