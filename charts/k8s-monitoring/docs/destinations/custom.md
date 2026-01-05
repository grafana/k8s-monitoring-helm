# Custom Destination

The custom destination allows you to create a destination using arbitrary Alloy configuration, and define how telemetry
data is sent to it. This can allow you to create new destinations that are not natively supported by the chart.

<!-- textlint-disable terminology -->
## Values

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | The name for this custom destination. |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config | string | `""` | The configuration for this destination. @ section -- General |
| ecosystem | string | `""` | The ecosystem for this destination. By setting this ecosystem, matching telemetry data sources might be auto-assigned to this destination. Options: `loki`, `otlp`, `prometheus`, `pyroscope` @ section -- General |
| logs.enabled | bool | `false` | Enable sending logs to this destination. @ section -- Logs |
| logs.target | string | `""` | The Alloy component reference for sending logs. @ section -- Logs |
| metrics.enabled | bool | `false` | Enable sending metrics to this destination. @ section -- Metrics |
| metrics.target | string | `""` | The Alloy component reference for sending metrics. @ section -- Metrics |
| profiles.enabled | bool | `false` | Enable sending profiles to this destination. @ section -- Profiles |
| profiles.target | string | `""` | The Alloy component reference for sending profiles. @ section -- Profiles |
| traces.enabled | bool | `false` | Enable sending traces to this destination. @ section -- Traces |
| traces.target | string | `""` | The Alloy component reference for sending traces. @ section -- Traces |
<!-- textlint-enable terminology -->

## Creating a custom destination

When creating a custom destination, you need to provide the `config`, define the ecosystem, enable at least one
supported data type, and provide the input for the enabled types.

### `config`

The `config` field is where your custom configuration goes.

### `ecosystem`

The "ecosystem" defines the type of the telemetry data that is natively supported by this destination. This will affect
which telemetry data sources are assigned to this destination and if any translations will be done.

The supported ecosystems are:

| Data Type | Ecosystems           | Description                                                                                                                                                   |
|-----------|----------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Metrics   | `prometheus`, `otlp` | When defined, the chart will automatically include either an `otelcol.receiver.prometheus` or `otelcol.exporter.prometheus` component to provide translation. |
| Logs      | `loki`, `otlp`       | When defined, the chart will automatically include either an `otelcol.receiver.loki` or `otelcol.exporter.loki` component to provide translation.             |
| Traces    | `otlp`               | All traces are handled in the `otlp` ecosystem.                                                                                                               |
| Profiles  | `pyroscope`          | All profiles are handled in the `pyroscope` ecosystem.                                                                                                        |

## Example

In this example, we define a Kafka custom destination. Since we're using the
[otelcol.exporter.kafka](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.exporter.kafka)
component, the ecosystem is set to `otlp`, because that is the expected data format. This component supports metrics,
logs, and traces, but in this definition, we only choose to send logs. We are also using a batch processor, so the
`input` field for the destination is set to the batch processor's input.

```yaml
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
```
