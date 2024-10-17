<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# k8s-monitoring-feature-frontend-observability

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)
Gathers frontend data

The Frontend Observability feature enables the collection of telemetry data from Frontend Applications, instrumented by
[Grafana Faro](https://github.com/grafana/faro-web-sdk).

## Testing

This chart contains unit tests to verify the generated configuration. A hidden value, `deployAsConfigMap`, will render
the generated configuration into a ConfigMap object. This ConfigMap is not used during regular operation, but it is
useful for showing the outcome of a given values file.

The unit tests use this to create an object with the configuration that can be asserted against. To run the tests, use
`helm test`.

Actual integration testing in a live environment should be done in the main [k8s-monitoring](../k8s-monitoring) chart.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-frontend-observability>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### General settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Full name override |
| nameOverride | string | `""` | Name override |
| port | int | `12347` | Port to listen for HTTP traffic on. |
