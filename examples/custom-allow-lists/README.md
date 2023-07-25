# Custom Allow Lists

This example shows how the metric allow lists can be modified to allow greater or fewer metrics to be sent to Prometheus.

In the example values file, here are the various settings and their effect:

| Allow List Value                                | Result                                      |
|-------------------------------------------------|---------------------------------------------|
| `["*"]` or `[]` or `null`                       | No filtering; allow all metrics             |
| `["node_*"]`                                    | Allow only metrics that start with `node_`  |
| `["kubelet_node_name","kubernetes_build_info"]` | Allow only specific metrics                 |

```yaml
cluster:
  name: custom-allow-lists-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    username: "12345"
    password: "It's a secret to everyone"

metrics:
  kube-state-metrics:
    allowList: ["*"]
  node-exporter:
    allowList: ["node_*"]
  kubelet:
    allowList: ["kubelet_node_name","kubernetes_build_info"]
  cadvisor:
    allowList:  # Just like previous, but in YAML list format
    - container_memory_cache
    - container_memory_rss
    - container_memory_swap
  cost:
    allowList: []
  enabled: true

logs:
  enabled: false
```