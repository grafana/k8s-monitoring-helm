# Credentials Auto-Configured from Grafana Cloud

This example shows how to auto-configure the external services using a single token from an API call to Grafana Cloud.  The token must have `metrics:write`, `logs:write`, `traces:write`, `profiles:write` and `stacks:read` permissions. Credit [theSuess](https://github.com/theSuess) for providing the original [example](https://github.com/grafana/agent-modules/blob/main/modules/grafana-cloud/autoconfigure/module.river).

```yaml
---
cluster:
  name: credentials-auto-configure

externalServices:
  prometheus:
    hostFrom: json_decode(remote.http.config_file.content)["hmInstancePromUrl"] + "/api/prom/push"
    basicAuth:
      usernameFrom: json_decode(remote.http.config_file.content)["hmInstancePromId"]
      passwordFrom: remote.kubernetes.secret.grafana_cloud.data["token"]
    secret:
      create: false
  loki:
    hostFrom: json_decode(remote.http.grafana_cloud.content)["hlInstanceUrl"] + "/loki/api/v1/push"
    basicAuth:
      usernameFrom: json_decode(remote.http.config_file.content)["hlInstanceId"]
      passwordFrom: remote.kubernetes.secret.grafana_cloud.data["token"]
    secret:
      create: false
  tempo:
    hostFrom: json_decode(remote.http.config_file.content)["htInstanceUrl"] + ":443"
    basicAuth:
      usernameFrom: json_decode(remote.http.config_file.content)["htInstanceId"]
      passwordFrom: remote.kubernetes.secret.grafana_cloud.data["token"]
    secret:
      create: false
  pyroscope:
    hostFrom: json_decode(remote.http.config_file.content)["hpInstanceUrl"]
    basicAuth:
      usernameFrom: json_decode(remote.http.config_file.content)["hpInstanceId"]
      passwordFrom: remote.kubernetes.secret.grafana_cloud.data["token"]
    secret:
      create: false
global:
  extraConfig: |-
    remote.kubernetes.secret "grafana_cloud" {
      namespace = "default"
      name = "grafana-cloud-credentials"
    }
    remote.http "grafana_cloud" {
      // replace YOURSTACKNAME with the name of your stack name
      // The API Token must have the stacks:read
      url = "https://grafana.com/api/instances/YOURSTACKNAME
      client {
        bearer_token = remote.kubernetes.secret.grafana_cloud.data["token"]
      }
      poll_frequency = "24h"
    }

logs:
  enabled: true
  pod_logs:
    enabled: true
  cluster_events:
    enabled: true
  journal:
    enabled: true

traces:
  enabled: true

profiles:
  enabled: true

extraObjects:
  - apiVersion: v1
    kind: Secret
    metadata:
      name: grafana-cloud-credentials
    type: Opaque
    data:
      token: SXQncyBhIHNlY3JldCB0byBldmVyeW9uZQ==
```
