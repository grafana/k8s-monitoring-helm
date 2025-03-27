<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# MongoDB Atlas databases

To gather metrics from MongoDB Atlas databases, Alloy uses the `discovery.http` component to ask MongoDB for the correct
URL for scraping metrics. It will then scrape the metrics from the URL provided by MongoDB.

Certain settings must be configured in MongoDB Atlas to allow scraping. Refer to the
[Integrate with Prometheus](https://www.mongodb.com/docs/atlas/tutorial/prometheus-integration/) documentation for full
details.

In this example, we utilize the `extraConfig` section to define the `discovery.http` component to request the scrape
target, and the `prometheus.scrape` component to scrape the database metrics. It uses a Kubernetes secret to store the
username, password, and group ID for the MongoDB Atlas database.

## Values

```yaml
---
cluster:
  name: mongodb-atlas-integration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

alloy-metrics:
  enabled: true
  extraConfig: |-
    remote.kubernetes.secret "mongodb_atlas" {
      name = "mongodb-atlas"
      namespace = "monitoring"
    }
    
    discovery.http "mongodb_atlas" {
      url = string.format("https://cloud.mongodb.com/prometheus/v1.0/groups/%s/discovery", remote.kubernetes.secret.mongodb_atlas.data["group_id"])

      basic_auth {
        username = nonsensitive(remote.kubernetes.secret.mongodb_atlas.data["username"])
        password = remote.kubernetes.secret.mongodb_atlas.data["password"]
      }
    }
  
    prometheus.scrape "mongodb_atlas" {
      targets         = discovery.http.mongodb_atlas.targets
      job_name        = "integrations/mongodb-atlas"
      scrape_interval = "10s"
      scheme          = "https"
  
      basic_auth {
        username = nonsensitive(remote.kubernetes.secret.mongodb_atlas.data["username"])
        password = remote.kubernetes.secret.mongodb_atlas.data["password"]
      }
  
      forward_to = [prometheus.remote_write.prometheus.receiver]
    }
```
