# Windows Exporter

This example shows how to set up the [Windows Exporter](https://github.com/prometheus-community/windows_exporter),
which allows for Node Exporter-like metrics to be gathered from Windows nodes in your mixed cluster.

The Windows Exporter is not enabled by default, so to enable it, you need to set these values:

-   `.prometheus-windows-exporter.enabled: true` - This will enable deployment of the Windows Exporter DaemonSet to all Windows nodes.
-   `.metrics.windows-exporter.enabled: true` - This generates the configuration for scraping the metrics emitted from Windows Exporter.

```yaml
cluster:
  name: default-values-test

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
  windows-exporter:
    enabled: true

prometheus-windows-exporter:
  enabled: true
```
