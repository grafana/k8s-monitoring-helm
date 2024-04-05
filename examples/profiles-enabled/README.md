# Profiles Enabled

This example contains the values required to enable gathering profile data, and sending them
to [Grafana Pyroscope](https://grafana.com/oss/pyroscope/).

```yaml
cluster:
  name: profiles-enabled-test

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
  pyroscope:
    host: https://pyroscope.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

profiles:
  enabled: true
```
