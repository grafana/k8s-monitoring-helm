# Destinations

Destinations are where telemetry data will be delivered. It can be a local service deployed on the same cluster, or a
remote, SaaS service. The different destination types actually about the protocol that is used to deliver that data.

| Type         | Protocol         | Telemetry Data        | Docs                    |
|--------------|------------------|-----------------------|-------------------------|
| `prometheus` | Remote Write     | Metrics               | [Docs](./prometheus.md) |
| `loki`       | Loki             | Logs                  | [Docs](./loki.md)       |
| `otlp`       | OTLP or OTLPHTTP | Metrics, Logs, Traces | [Docs](./otlp.md)       |
| `pyroscope`  | Pyroscope        | Profiles              | [Docs](./pyroscope.md)  |

## Configuration

You can specify multiple destinations in the `destinations` section of the configuration file. Each destination must
have a name and a type. The type determines the protocol that will be used to deliver the telemetry data.

## What about Tempo?

There is no `tempo` destination for traces, because [Tempo](https://grafana.com/oss/tempo/) uses the OTLP protocol to
receive traces. So, you can use the `otlp` destination to send traces to Tempo.

## Example

Here is an example of a destinations section:

```yaml
destinations:
  - name: hostedMetrics
    type: prometheus
    url: https://prometheus.example.com/api/prom/push
    auth:
      type: basic
      username: "my-username"
      password: "my-password"

  - name: localPrometheus
    type: prometheus
    url: http://prometheus.monitoring.svc.cluster.local:9090

  - name: hostedLogs
    type: loki
    url: https://loki.example.com/loki/api/v1/push
    auth:
      type: basic
      username: "my-username"
      password: "my-password"
      tenantIdFrom: env("LOKI_TENANT_ID")

  - name: otlpGateway
    type: otlp
    url: https://otlp.example.com:4317/v1/traces
    auth:
      type: basic
      username: "my-username"
      password: "my-password"
    metrics: { enabled: true }
    logs:    { enabled: true }
    traces:  { enabled: true }
```

## Assignment

When there are multiple destinations that support the same type of telemetry data, the Helm chart will try to
intelligently assign data from features to destinations. The assignment algorithm is:

1.  Has the feature defined its own `destintaions` list? If so, use that.
2.  Assign any destinations to features that are in the same ecosystem.
3.  If there are no matching ecosystem destinations, assign any destinations that support the telemetry data type.

Matching ecosystems first is important because it prevents translations between ecosystems, which may be imperfect.

### Examples

These examples demonstrate how the assignment algorithm works.

#### Example 1

Assume we have a feature that gathers logs in the Loki ecosystem (e.g. via the `loki.source.file` Alloy component).
Next, assume we have defined two destinations: a `loki` type destination, and an `oltp` type destination that supports
logs.

```yaml
destinations:
  - name: a
    type: loki

  - name: b
    type: otlp
    logs:
      enabled: true

podLogs:
  enabled: true
```

The Kubernetes Observability Helm chart will forward logs from the feature to the `loki` destination, because it is in
the same ecosystem. The `otlp` destination will not receive any logs.

![Example 1](./.images/example1.png)

#### Example 2

If we explicitly set the list of destinations, we can override the assignment algorithm and send logs to both
destinations. Loki logs will go through a translator component to convert them to the OTLP ecosystem.

```yaml
destinations:
  - name: a
    type: loki

  - name: b
    type: otlp
    logs:
      enabled: true

podLogs:
  enabled: true
  destinations: [a, b]
```

![Example 2](./.images/example2.png)

#### Example 3

If only the `otlp` destination is defined, the logs will be sent to that destination without having to be explicitly
defined.

```yaml
destinations:
  - name: b
    type: otlp
    logs:
      enabled: true

podLogs:
  enabled: true
```

![Example 3](./.images/example3.png)

## Contributing

Destinations use a specific set of files to define the destination configuration. These files are used to generate the
destination configuration and documentation.

Several files are used for defining a destination:

-   `destinations/<destination slug>-values.yaml` - The values file that defines the valid configuration options
  for the destination. It is a YAML file in the style of a Helm chart values file. This file is used to generate
  documentation and schema files that will validate the options when deploying.
-   `templates/destinations/_destination_<destination slug>.tpl` - The template file that generates the
  destination configuration. This file is required to implement the following template functions:
    -   `destinations.<destination slug>.alloy` - Returns the Alloy configuration for the destination.
    -   `destinations.<destination slug>.supports_metrics` - Returns true if the destination supports metrics.
    -   `destinations.<destination slug>.supports_logs` - Returns true if the destination supports logs.
    -   `destinations.<destination slug>.supports_traces` - Returns true if the destination supports traces.
    -   `destinations.<destination slug>.supports_profiles` - Returns true if the destination supports profiles.
    -   `destinations.<destination slug>.ecosystem` - Returns the telemetry data ecosystem.
    -   `destinations.<destination slug>.<ecosystem>.<data type>.target` - Returns the name of the Alloy target where
        telemetry data of the matching type and ecosystem should be sent.
    -   `secrets.list.<destination slug>` - Returns a YAML list of values that should be considered secrets. This will
        control how the secrets for this destination are generated and interfaced in the Alloy config.
  Multiple target template functions can be made to support converting from one ecosystem to another.
-   `docs/destinations/.doc_templates/<destination slug>.gotmpl` - The optional documentation template file for the
  destination. This file can include examples, usage instructions, and other information about the destination.

### Generated files

When using `make build`, the following files will be updated or generated:

-   `docs/destinations/<destination slug>.md` - The documentation file for the destination. This file is generated
  from the destination values file and the destination template file.
-   `values/destinations/<destination slug>.schema.json` - The JSON schema file for the destination values file. This
  file is generated from the destination values file.
-   `templates/destinations/_destination_types.tpl` - This template file is generated with the list of all possible
  destination types.
