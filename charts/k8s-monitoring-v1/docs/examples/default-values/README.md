# Default Values

This example contains the bare minimum to deploy the Kubernetes Monitoring Helm chart.

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
```
