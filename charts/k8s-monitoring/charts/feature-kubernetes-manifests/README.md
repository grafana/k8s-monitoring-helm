<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Kubernetes Manifests

The Kubernetes Manifests feature enables the collection of Kubernetes manifests from the objects in the cluster.

## Usage

```yaml
kubernetesManifests:
  enabled: true
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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-kubernetes-manifests>
<!-- markdownlint-enable list-marker-space -->

## Values

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.namespaceOverride | string | `""` | Override the namespace for namespaced resources created by this chart. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobLabel | string | `"integrations/kubernetes/manifests"` | The value for the job label. |
<!-- markdownlint-enable no-bare-urls -->
