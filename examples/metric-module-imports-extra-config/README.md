# Alloy Modules extraConfig

This example shows a how to leverage `extraConfig` to import custom modules that might not adhere to the opinionated way that the `metrics.alloyModules` does.

```yaml
cluster:
  name: metric-module-imports-extra-config

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

extraConfig: |-
  import.git "memcached" {
    repository = "https://github.com/grafana/alloy-modules.git"
    revision = "main"
    path = "modules/databases/kv/memcached/metrics.alloy"
    pull_frequency = "15m"
  }

  // get the targets
  memcached.kubernetes "targets" {}

  // scrape the targets
  memcached.scrape "metrics" {
    targets = memcached.kubernetes.targets.output
    forward_to = [prometheus.remote_write.metrics_service.receiver]
  }
```
