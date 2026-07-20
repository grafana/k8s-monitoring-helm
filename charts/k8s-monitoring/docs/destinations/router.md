# router

<!-- textlint-disable terminology -->
## Values

### Routing

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| attribute | string | `"k8s.namespace.name"` | The resource attribute (OTLP-ecosystem telemetry) or label (Prometheus/Loki/Pyroscope-ecosystem telemetry) whose value decides which downstream destination(s) a given record is routed to. Must start with a letter or underscore and contain only letters, digits, underscores, dots, slashes, and hyphens (no quotes, backticks, backslashes, or whitespace). The well-known value `k8s.namespace.name` is automatically mapped to the `namespace` label for label-based ecosystems. Any other attribute that is ALSO a valid Prometheus label name (letters/digits/underscore only, starting with a letter or underscore -- so no dots, slashes, or hyphens) is used verbatim as the label name. Attributes outside that stricter label-name grammar have no label equivalent, so label-based ecosystems fall back to `defaultDestinations` only. |
| defaultDestinations | list | `[]` | Destinations to fall back to when no route matches. MANDATORY: every router must define at least one default destination, otherwise unmatched telemetry has nowhere to go. |
| routes | list | [] | Routing rules, evaluated in declaration order: the first rule whose `match` matches wins. Records that don't match any rule (or whose matched rule does not list a destination for a given signal) fall back to `defaultDestinations`. |

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| disabled | bool | `false` | Set to `true` to disable this destination. Disabled destinations are excluded from all telemetry data flows, which is useful for removing a destination that was defined in a shared or parent values file. |
| name | string | `""` | The name for this router destination. A router is not a real telemetry backend: it is a virtual destination that a feature points at (`destinations: [myRouter]`) which then fans telemetry out to real destinations based on an attribute value. |
<!-- textlint-enable terminology -->
