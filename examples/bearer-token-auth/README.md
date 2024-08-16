# Default Values

Example to deploy the Kubernetes Monitoring Helm chart.

```yaml
cluster:
  name: default-values-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    authMode: bearerToken
    bearerToken:
      token: "example-bearer-token"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
```
