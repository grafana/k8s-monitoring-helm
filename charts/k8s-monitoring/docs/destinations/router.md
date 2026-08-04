# router

<!-- textlint-disable terminology -->
## Values

### Routing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| defaultDestinations | list | `[]` | Destinations to fall back to when no route matches. MANDATORY: every router must define at least one default destination, otherwise unmatched telemetry has nowhere to go. |
| ecosystem | string | `""` | The collection pipeline this router routes on: `otlp`, `prometheus`, `loki`, or `pyroscope`. `otlp` routes OpenTelemetry Protocol data (metrics, logs, and traces) by matching resource attributes with OTTL. `prometheus`, `loki`, and `pyroscope` route the corresponding label-based pipeline (metrics, logs, and profiles respectively) by matching labels. The ecosystem also determines how each route's `match` conditions are written: `resourceAttribute` for `otlp`, `label` for the others. A feature may only route through a router whose ecosystem matches the pipeline that feature collects on. |
| routes | list | [] | Routing rules, evaluated in declaration order: the first rule whose `match` conditions all match wins. Records that don't match any rule (or whose matched rule does not list a destination for a given signal) fall back to `defaultDestinations`. Each route's `match` is a list of `{<field>, op, value}` conditions that are ANDed together, where `<field>` is `resourceAttribute` (for an `otlp` router) or `label` (for a `prometheus`/`loki`/`pyroscope` router). `op` is one of `equals`, `notEquals`, `in`, `matches`, `notMatches` (`notEquals` and `notMatches` are `otlp`-only). `value` is a string (or a list of strings for `in`). |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| disabled | bool | `false` | Set to `true` to disable this destination. Disabled destinations are excluded from all telemetry data flows, which is useful for removing a destination that was defined in a shared or parent values file. |
| name | string | `""` | The name for this router destination. A router is not a real telemetry backend: it is a virtual destination that a feature points at (`destinations: [myRouter]`) which then fans telemetry out to real destinations based on the route match conditions. |
<!-- textlint-enable terminology -->
