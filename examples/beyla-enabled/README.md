# Beyla Enabled

This example contains the values required to enable [Grafana Beyla](https://github.com/grafana/beyla) to enable automatic instrumentation of deployed services using eBPF. This is example enforces running Alloy with the `securityContext` settings required to run Beyla in privileged mode.

```yaml
cluster:
  name: beyla-enabled-test

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
  tempo:
    host: https://tempo.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

beyla:
  enabled: true
  debug: true
  process: true
  traces: true
  network: true
  namespaces: ["default"]

traces:
  enabled: true

alloy:
  alloy:
    stabilityLevel: public-preview
    clustering: {enabled: false}
    securityContext:
      privileged: true
      runAsGroup: 0
      runAsUser: 0

  controller:
    type: daemonset
    hostPID: true
```
