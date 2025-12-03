<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Kubernetes Manifests

TODO

## Usage

```yaml
kubernetesManifests:
  enabled: true
  ... [values](#values)
```

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
| petewall | <pete.wall@grafana.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-kubernetes-manifests>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Image

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image | object | `{"digest":"","pullPolicy":"IfNotPresent","pullSecrets":[],"registry":"ghcr.io","repository":"grafana/helm-chart-toolbox-kubectl","tag":"0.1.3"}` | The image to run to get the Kubernetes manifests from this cluster. It must contain `kubectl` and `jq` at a minimum. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kinds | object | `{"cronjobs":{"gather":false},"daemonsets":{"gather":false},"deployments":{"gather":false},"pods":{"gather":false},"statefulsets":{"gather":false}}` | The kinds of manifests to gather. |
| namespaces | list | `[]` | Only gather manifests from these namespaces. If empty, gather from all. This affects the manifests gathered, but Also if this chart deploys ClusterRoles and ClusterRoleBindings or Roles and RoleBindings. |
| refreshInterval | string | `"1d"` | How frequently to refresh all manifests, regardless of if they have changed. At maximum, this should be set lower Than the retention period for your log storage. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.image.registry | string | `""` |  |
