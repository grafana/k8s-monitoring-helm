# Processors

Processors are middleware that transform telemetry data after a feature gathers it but before it reaches a destination.
They can rewrite labels, drop fields, redact values, batch records, or otherwise modify data in flight. A feature can
opt in to a chain of processors; the chart renders the processor pipeline and wires it between the feature and its
destinations.

| Type     | Description                                                                       | Docs                |
|----------|-----------------------------------------------------------------------------------|---------------------|
| `custom` | Arbitrary Alloy block authored by the user. Supports any (type, ecosystem) tuple. | [Docs](./custom.md) |

## Configuration

Processors are defined at the top level under `dataProcessors`. Each processor has a name you choose and a `type` that
determines its behavior. A processor declares which `(telemetry type, ecosystem)` tuples it supports by enabling them
in its values; a feature can only attach the processor for tuples both sides support.

```yaml
dataProcessors:
  <processor name>:
    type: custom
    ...
```

Features opt in to processors by listing them under the feature's `dataProcessors` key, in chain order:

```yaml
clusterEvents:
  dataProcessors: [redact, label]

dataProcessors:
  redact:
    type: custom
    ...
  label:
    type: custom
    ...
```

The chart resolves the chain per `(type, ecosystem)`: processors that don't support a tuple are dropped from the chain
for that tuple, and the validator surfaces unknown processor names as errors.

## How it works

For each `(feature, type, ecosystem)` tuple where the feature has at least one applicable processor, the chart renders:

1.  A **stamper** that receives data from the feature's module, attaches a `selected_destinations` label/attribute
    listing the destinations the feature would have selected on its own, and forwards into the first processor in the
    chain.
2.  Each **processor's user-config block** for that tuple. Each block writes its terminal `forward_to` to a stable
    per-processor output sink.
3.  An **output sink** per processor that forwards to either the next processor's input (intermediate) or to
    per-destination gates (terminal). For OTLP the sink is an `otelcol.processor.batch`, so records are batched once
    per processor regardless of how many destinations follow.
4.  A **destination gate** per `(terminal processor, destination)` that keeps only records whose `selected_destinations`
    contains that destination's name, strips the label/attribute, and forwards to the destination's receiver.

The `selected_destinations` stamp lets the chart preserve per-feature destination assignment through a shared chain:
two features that share a processor but resolve to different destinations don't cross-pollinate.

When a feature has no applicable processors for a `(type, ecosystem)` tuple, the chart emits destination receivers
directly, exactly as if no processor support existed. Features that don't opt in pay no cost.

## Example

```yaml
dataProcessors:
  add-cluster-label:
    type: custom
    metrics:
      prometheus:
        enabled: true
        input: prometheus.relabel.add_cluster_label_in.receiver
        config: |
          prometheus.relabel "add_cluster_label_in" {
            forward_to = [prometheus.relabel.add_cluster_label_out_metrics_prometheus.receiver]
            rule {
              target_label = "cluster"
              replacement  = "production"
            }
          }

clusterMetrics:
  enabled: true
  dataProcessors: [add-cluster-label]
```

## Contributing

Processors use a specific set of files to define the processor configuration. These files are used to generate the
processor configuration and documentation.

Several files are used for defining a processor:

-   `dataProcessors/<processor type>-values.yaml` - The values file that defines the valid configuration options for the
    processor type. It is a YAML file in the style of a Helm chart values file. This file is used to generate
    documentation and schema files that will validate the options when deploying.
-   `templates/dataProcessors/_dataProcessor_<processor type>.tpl` - The template file that generates the processor
    configuration. This file is required to implement the following template functions, for each `(telemetry type, ecosystem)`
    tuple the processor supports:
    -   `dataProcessors.<processor type>.supports_<telemetry type>_<ecosystem>` - Returns `"true"` if the processor supports that
        tuple.
    -   `dataProcessors.<processor type>.alloy.<ecosystem>.<telemetry type>.input` - Returns the Alloy component reference where the
        chart should forward data into the user's pipeline.
    -   `dataProcessors.<processor type>.alloy.<ecosystem>.<telemetry type>.config` - Returns the Alloy block defining the user's
        pipeline. Its terminal `forward_to` must target the chart-generated output sink for this tuple (see the
        [custom processor docs](./custom.md) for the naming convention).
-   `docs/dataProcessors/.doc_templates/<processor type>.gotmpl` - The optional documentation template file for the
    processor. This file can include examples, usage instructions, and other information about the processor.

### Generated files

When using `make build`, the following files will be updated or generated:

-   `docs/dataProcessors/<processor type>.md` - The documentation file for the processor type. This file is generated from the
    processor values file and the processor template file.
-   `schema-mods/definitions/<processor type>-dataProcessor.schema.json` - The JSON schema file for the processor type values.
    This file is generated from the processor type values file.
-   `templates/dataProcessors/_dataProcessor_types.tpl` - This template file is generated with the list of all possible
    processor types.
