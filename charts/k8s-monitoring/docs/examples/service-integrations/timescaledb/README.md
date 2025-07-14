<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Timescale databases

To gather metrics from timescale  databases, Alloy uses the `discovery.http` component to ask TimescaleDB for the correct
URL for scraping metrics. It will then scrape the metrics from the URL provided by TimescaleDB.

Certain settings must be configured in TimescaleDB or TigerData to allow scraping. Refer to the
[Integrate with Prometheus](https://docs.tigerdata.com/use-timescale/latest/metrics-logging/metrics-to-prometheus/) documentation for full
details.

In this example, we utilize the `extraConfig` section to define the `discovery.http` component to request the scrape
target, and the `prometheus.scrape` component to scrape the database metrics. It uses a Kubernetes secret to store the
username, password, and group ID for the MongoDB Atlas database.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: timescaledb-integration-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

alloy-metrics:
  enabled: true
  extraConfig: |-
    remote.kubernetes.secret "timescale_db" {
      name = "timescale-db"
      namespace = "observability"
    }

    prometheus.scrape "timescale_db" {
      targets = [
        {"__address__" = convert.nonsensitive(remote.kubernetes.secret.timescale_db.data["url"])},
      ]

      job_name        = "integrations/timescale_db"
      scrape_interval = "30s"
      scheme          = "https"
      metrics_path    = "/metrics"

      basic_auth {
        username = nonsensitive(remote.kubernetes.secret.timescale_db.data["username"])
        password = remote.kubernetes.secret.timescale_db.data["password"]
      }

      forward_to = [prometheus.remote_write.mimir.receiver]
      // forward_to = [prometheus.relabel.filter_timescale.receiver ( Enable this if you want to keep only fixed labels as exporter is common for all)
    }

    /* Enable this to keep fixed labels 
    prometheus.relabel "filter_timescale" {
      rule {
        action        = "keep"
        source_labels = ["service_id"]
        regex         = convert.nonsensitive(remote.kubernetes.secret.timescale_db.data["service_id"])
      }

      forward_to = [prometheus.remote_write.mimir.receiver]
    }
    */


```
<!-- textlint-enable terminology -->
