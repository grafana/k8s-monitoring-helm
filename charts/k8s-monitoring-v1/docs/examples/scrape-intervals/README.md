# Scrape Intervals

This example shows how to modify the default scrape interval for metrics. The default scrape interval for
[Grafana Alloy](https://grafana.com/docs/alloy/latest/reference/components/prometheus.scrape/#arguments) is `60s`,
and this chart does not deviate from this. But there are methods for overriding that scrape interval.

-   `metrics.scrapeInterval` sets the scrape interval for all metric sources.
-   `metrics.<source>.scrapeInterval` sets the scrape interval for a specific metric source.

Setting the first will set it for all metric sources (e.g. it changes the default), while setting the second will
override the first for that specific metric source.

In the example values file, here are the various settings and their effect:

```yaml
cluster:
  name: custom-scrape-intervals-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: "12345"
      password: "It's a secret to everyone"

metrics:
  scrapeInterval: 2m
  kube-state-metrics:
    scrapeInterval: 30s
  node-exporter:
    scrapeInterval: 60s

logs:
  pod_logs:
    enabled: false

  cluster_events:
    enabled: false
```
