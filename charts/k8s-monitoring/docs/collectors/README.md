# Collectors

Collectors are the [Grafana Alloy](https://grafana.com/docs/alloy/latest/) instances that gather, process, and forward
telemetry data to your destinations. The Kubernetes Monitoring Helm chart deploys collectors using the
[Alloy Operator](https://github.com/grafana/alloy-operator), with each instance defined as its own entry in the
`collectors` section of the values file.

Splitting telemetry gathering across multiple collectors lets each instance be sized, scheduled, and configured
independently for the workload it handles. For example, log gathering typically runs as a DaemonSet so each node's
files can be read locally, while metrics gathering can run as a clustered StatefulSet to distribute scrape targets
across replicas.

## Configuration

Each collector is defined under the `collectors` key, with a name you choose. Features in the chart reference
collectors by name (for example, `clusterEvents.collector: alloy-singleton`), so the collector must exist before a
feature can use it.

```yaml
collectors:
  <collector name>:
    presets: [...]  # Configuration presets
    alloy:          # Settings for the Alloy instance
      ...
    controller:     # Settings for the Alloy controller (workload type, replicas, tolerations, etc.)
      ...
```

Common collector names used by features in this chart are `alloy-metrics`, `alloy-logs`, `alloy-singleton`,
`alloy-receiver`, and `alloy-profiles`, but you can name them however you like.

### Example

```yaml
collectors:
  alloy-metrics:
    presets: [medium, clustered, statefulset]

  alloy-logs:
    presets: [small, filesystem-log-reader, daemonset]

  alloy-singleton:
    presets: [small, deployment]

clusterEvents:
  collector: alloy-singleton
```

See the [Alloy collector reference](./alloy.md) for the full list of available settings on each collector.

## Presets

Presets are predefined configuration bundles that set common options on a collector, such as workload type
(`daemonset`, `statefulset`, `deployment`), clustering, sizing (`small`, `medium`, `large`, `xlarge`), and
filesystem access for log reading. Multiple presets can be applied to a single collector, with later presets
overriding earlier ones.

```yaml
collectors:
  alloy-metrics:
    presets: [clustered, statefulset, medium]
```

See the [presets reference](./presets/README.md) for the full list of available presets.

## Common settings with `collectorCommon`

The `collectorCommon` section applies settings to every collector, so you can configure shared options once instead
of repeating them on each instance. Settings on an individual collector still take precedence over `collectorCommon`.

```yaml
collectorCommon:
  alloy:
    extraEnv:
      - name: CLUSTER_NAME
        value: my-cluster

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
```

Both `alloy-metrics` and `alloy-logs` will receive the `CLUSTER_NAME` environment variable from `collectorCommon`.

## See also

-   [Alloy collector reference](./alloy.md) — full list of values for each collector instance.
-   [Presets reference](./presets/README.md) — list of available presets and what each one configures.
