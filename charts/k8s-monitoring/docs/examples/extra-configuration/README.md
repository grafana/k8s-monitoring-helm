<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Extra Configuration

This example shows how to include additional configuration components to the Alloy instances. These components are added
to any existing configuration and does not replace it or modify it in any way.

In the example below, note that the `discovery.kubernetes.animal_service` component discovers the Kubernetes Service by
namespace and label selectors. Metrics found are then forwarded to `prometheus.remote_write.<destination-name>.receiver`
for delivery.

## Values

```yaml
---
cluster:
  name: extra-configuration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

alloy-metrics:
  enabled: true
  extraConfig: |
    discovery.kubernetes "animal_service" {
      role = "service"
      namespaces {
        names = ["zoo"]
      }
      selectors {
        role = "service"
        label = "app.kubernetes.io/name=animal-service"
      }
    }
    prometheus.scrape "animal_service" {
      job_name   = "animal_service"
      targets    = discovery.kubernetes.animal_service.targets
      forward_to = [prometheus.remote_write.prometheus.receiver]
    }
```
