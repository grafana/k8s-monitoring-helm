# Alloy Modules

This example shows a how to leverage the [Alloy Modules](https://github.com/grafana/alloy-modules) for collecting metrics.  These modules are opinionated, where each module has at least the following two components defined:

1.  `kubernetes` Used to find targets in the cluster
2.  `scrape` Used to scrape the found targets.

```yaml
cluster:
  name: metric-module-imports

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

metrics:
  alloyModules:
    connections:
      - alias: grafana
        repository: https://github.com/grafana/alloy-modules.git
        revision: main
        pull_frequency: 15m
        default: true
    modules:
      - alias: memcached
        path: modules/databases/kv/memcached/metrics.alloy
      - alias: loki
        path: modules/databases/timeseries/loki/metrics.alloy
      - alias: mimir
        path: modules/databases/timeseries/mimir/metrics.alloy
      - alias: tempo
        path: modules/databases/timeseries/tempo/metrics.alloy
      - alias: grafana
        path: modules/ui/grafana/metrics.alloy
```
