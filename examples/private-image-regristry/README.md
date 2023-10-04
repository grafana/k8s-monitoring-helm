# Private Image Registry

This example shows how to override the container image registries for every subchart. This can be used to support
air-gapped environments, or in environments where you might not want to use public image registries.

```yaml
cluster:
  name: private-image-regristry-test

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

opencost:
  opencost:
    exporter:
      image:
        registry: "my.registry.com"

kube-state-metrics:
  image:
    registry: "my.registry.com"

prometheus-node-exporter:
  image:
    registry: "my.registry.com"

prometheus-windows-exporter:
  image:
    registry: "my.registry.com"

grafana-agent:
  image:
    registry: "my.registry.com"

  configReloader:
    image:
      registry: "my.registry.com"

grafana-agent-logs:
  image:
    registry: "my.registry.com"

  configReloader:
    image:
      registry: "my.registry.com"
```
