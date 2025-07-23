<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Profiles Rceiver

This feature provides a receiver for profiles where processing rules can be defined before delivering to the profiles
destination.

## Usage

profilesReceiver:
  enabled: true
  ... [values](#values)

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

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-profiles-receiver>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Listener Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| port | int | `4040` | Port number on which the server listens for new connections. |

### Profile Processing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| profileProcessingRules | string | `""` | Rule blocks to be added to the pyroscope.relabel component for received profiles. These relabeling rules are applied to profiles received by this feature. ([docs](https://grafana.com/docs/alloy/latest/reference/components/pyroscope/pyroscope.relabel/#rule)) |
