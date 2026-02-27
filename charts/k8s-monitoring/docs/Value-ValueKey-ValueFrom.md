# Password, PasswordKey, and PasswordFrom

Several values in the k8s-monitoring Helm chart accept one of three similarly named options: `password`, `passwordKey`,
and `passwordFrom`. This pattern exists across destinations, collectors, integrations, and remote config blocks. The
goal of each option is the same—provide a secret value to Alloy—but they differ in *where* that value comes from, as
highlighted in GitHub issues #1854 and #2214.

## When to use each option

| Option        | Source of the secret                                                                 | Chart behavior                                                                                                        |
|---------------|---------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| `password`    | Literal string stored directly in your values file.                                  | Helm creates (or updates) a Kubernetes Secret that stores the password; Alloy loads it from that managed secret.      |
| `passwordKey` | A key inside a Kubernetes Secret **you manage yourself**.                            | Helm references your secret (configure `secret.create: false`, `secret.name`, `secret.namespace`) and reads the key.  |
| `passwordFrom`| Raw Alloy config that resolves to the password at runtime (env var, file, HTTP, etc).| Helm injects the expression verbatim into the generated Alloy config; you are responsible for making it valid Alloy.  |

### `password`

```yaml
destinations:
  - name: metrics-service
    type: prometheus
    url: https://prom.example.com/api/prom/push
    auth:
      type: basic
      username: observer
      password: my-super-secret
```

Use this when you are comfortable letting the chart manage the underlying secret. Helm will store this in a Kubernetes
secret, and Alloy will discover this secret at runtime.

### `passwordKey`

```yaml
destinations:
  - name: metrics-service
    type: prometheus
    url: https://prom.example.com/api/prom/push
    auth:
      type: basic
      usernameKey: prom-username
      passwordKey: prom-password
    secret:
      create: false
      name: my-credentials
      namespace: monitoring
```

Choose this when another workflow (SealedSecrets, External Secrets Operator, Flux, etc.) is already creating a secret
and you simply want Alloy to know how to reference the right field in that secret.

In the above example, a secret like this is expected:

```yaml
FILL IN HERE
```

### `passwordFrom`

```yaml
destinations:
  - name: metrics-service
    type: prometheus
    url: https://prom.example.com/api/prom/push
    auth:
      type: basic
      username: observer
      passwordFrom: sys.env("PROM_PASSWORD")
```

This option lets you set raw Alloy configuration for the field. The value is not quoted or modified, so you must use any
Alloy expression that resolves to a string. Some examples are:

*   [sys.env](https://grafana.com/docs/alloy/latest/reference/stdlib/sys/#sysenv) - Environment variables
*   [local.file](https://grafana.com/docs/alloy/latest/reference/components/local/local.file/) - Contents from a file
*   [remote.http](https://grafana.com/docs/alloy/latest/reference/components/remote/) - Result from an HTTP request
