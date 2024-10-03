# Environment Variables

In this example, we show how to set environment variables in the Alloy instance and a few examples of how to use them.

This can be extended to set environment variables in any of the Alloy instances.

```yaml
---
cluster:
  name: environment-variables-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
    externalLabelsFrom:
      company: env("COMPANY")     # label set from environment variable
      team: env("team")           # label set from environment variable found in the ConfigMap
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

metrics:
  # Environment variable used in a relabeling rule
  extraMetricRelabelingRules: |-
    rule {
      target_label = "region"
      replacement = env("region")
    }

alloy:
  alloy:
    extraEnv:       # Set environment variables directly
      - name: COMPANY
        value: "Widget Co"
    extraEnvFrom:   # Set environment variables from a ConfigMap
      - configMapRef:
        name: team-params

# Deploy the ConfigMap with the environment variables. Typically, this would already exist in your cluster.
extraObjects:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: common-params
    data:
      team: "Team A"
      region: "midwest"
```
