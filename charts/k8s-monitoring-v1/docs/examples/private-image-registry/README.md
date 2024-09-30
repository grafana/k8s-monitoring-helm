# Private Image Registry

This example shows how to override the container image registries for every subchart. This can be used to support
air-gapped environments, or in environments where you might not want to use public image registries.

This example shows using the `global` object to set registry and pull secrets for most subcharts. However, subcharts
use different methods, even within the global objects, so it needs to be defined in both ways.

If you do not want to use the `global` object, registry and pull secrets can be set on each subchart individually.

```yaml
cluster:
  name: private-image-registry-test

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

# Dependent charts use two methods for global image registry and pull secrets
# so we need to define it both ways.
global:
  image:
    registry: my.registry.com
    pullSecrets:
      - name: my-registry-creds
  imageRegistry: my.registry.com
  imagePullSecrets:
    - name: my-registry-creds

# OpenCost does not use the global settings, so it needs to be set individually
opencost:
  imagePullSecrets:
    - name: my-registry-creds
  opencost:
    exporter:
      image:
        registry: my.registry.com
```
