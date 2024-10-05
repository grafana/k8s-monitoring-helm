<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Annotation-based autodiscovery

This example shows how to enable the annotation-based autodiscovery feature, which makes it easy to add scrape targets.
With this feature enabled, any Kubernetes Pods or Services with the `k8s.grafana.com/scrape` annotation set to
`true` will be automatically discovered and scraped by the collector. There are several other annotations that can be
used to customize the behavior of the scrape configuration, such as:

*   `k8s.grafana.com/job`: The value to use for the `job` label.
*   `k8s.grafana.com/instance`: The value to use for the `instance` label.
*   `k8s.grafana.com/metrics.path`: The path to scrape for metrics. Defaults to `/metrics`.
*   `k8s.grafana.com/metrics.portNumber`: The port on the Pod or Service to scrape for metrics. This is used to target a specific port by its number, rather than all ports.
*   `k8s.grafana.com/metrics.portName`: The named port on the Pod or Service to scrape for metrics. This is used to target a specific port by its name, rather than all ports.
*   `k8s.grafana.com/metrics.scheme`: The scheme to use when scraping metrics. Defaults to `http`.
*   `k8s.grafana.com/metrics.scrapeInterval`: The scrape interval to use when scraping metrics. Defaults to `60s`.

For more information, see the [Annotation Autodiscovery feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-annotation-autodiscovery).

## Values

```yaml
---
cluster:
  name: annotation-autodiscovery-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

annotationAutodiscovery:
  enabled: true

alloy-metrics:
  enabled: true
```
