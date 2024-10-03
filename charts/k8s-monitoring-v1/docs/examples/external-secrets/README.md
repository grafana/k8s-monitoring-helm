# External Secrets

Using external secrets allows you to store the hostnames, usernames, passwords and other sensitive data in a pre-made
Kubernetes Secret object. This example shows how to reference that secret, as well the keys within it:

```yaml
cluster:
  name: external-secrets-test
externalServices:
  prometheus:
    hostKey: prom_hostname
    secret:
      create: false
      name: alloy-secret
      namespace: monitoring
    basicAuth:
      usernameKey: prom_username
      passwordKey: password

  loki:
    hostKey: loki_hostname
    secret:
      create: false
      name: alloy-secret
      namespace: monitoring
    basicAuth:
      usernameKey: loki_username
      passwordKey: password
```

here is the secret object itself:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alloy-secret
  namespace: monitoring
type: Opaque
stringData:
  prom_hostname: "https://prometheus.example.com"
  prom_username: "12345"
  loki_hostname: "https://loki.example.com"
  loki_username: "12345"
  password: "It's a secret to everyone"
```
