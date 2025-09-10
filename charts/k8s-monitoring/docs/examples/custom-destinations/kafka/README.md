<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Custom Destination: Kafka

This custom destination shows how to configure a destination that sends data to Apache Kafka. This example specifically
only chooses to send Kubernetes Cluster Events as logs, but the
[Kafka exporter](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.exporter.kafka) does support
sending metrics and traces as well.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: kafka-custom-destination

destinations:
  - name: kafka
    type: custom
    config: |
      otelcol.processor.batch "kafka" {
        output {
          logs = [otelcol.exporter.kafka.kafka.input]
        }
      }

      otelcol.exporter.kafka "kafka" {
        logs {
          topic = "cluster_events"
          encoding = "raw"
        }
        brokers          = ["my-cluster-kafka-brokers.kafka.svc:9092"]
        protocol_version = "2.0.0"
      }

    ecosystem: otlp
    logs:
      enabled: true
      target: otelcol.processor.batch.kafka.input

clusterEvents:
  enabled: true
  destinations: [kafka]

alloy-singleton:
  enabled: true
  liveDebugging:
    enabled: true
```
<!-- textlint-enable terminology -->
