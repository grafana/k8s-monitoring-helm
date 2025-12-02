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

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.digest | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.pullSecrets | list | `[]` |  |
| image.registry | string | `"ghcr.io"` |  |
| image.repository | string | `"grafana/helm-chart-toolbox-kubectl"` |  |
| image.tag | string | `"0.1.2"` |  |
| kinds.cronjobs.gather | bool | `true` |  |
| kinds.daemonsets.gather | bool | `true` |  |
| kinds.deployments.gather | bool | `true` |  |
| kinds.pods.gather | bool | `true` |  |
| kinds.statefulsets.gather | bool | `true` |  |
| namespaces | list | `[]` |  |
| refreshInterval | int | `3600` |  |
