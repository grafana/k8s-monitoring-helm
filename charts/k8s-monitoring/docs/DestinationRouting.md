# Destination routing

The `router` destination type sends telemetry to different real destinations based on the value of
an attribute (OpenTelemetry Protocol telemetry) or a mapped label (scraped metrics, Loki logs, and
Pyroscope profiles), all from a single release. This is useful for splitting telemetry by tenant,
team, or environment without deploying a separate collector or release per group.

## What a router is

A router is not a telemetry backend. It never receives a URL, credentials, or a protocol. It is a
virtual destination: a named entry under `destinations` with `type: router` that a feature points
at the same way it would point at any other destination, by listing its name in that feature's
`destinations`. When a record reaches the router, the router evaluates its route table, decides
which real destination(s) the record should go to, and forwards it there.

```yaml
destinations:
  platform:
    type: otlp
    url: http://tempo.tempo.svc:443/otlp
  stack-a:
    type: otlp
    url: http://tempo-stack-a.tempo.svc:443/otlp
  tenantRouter:
    type: router
    routes:
      - match:
          equals: tenant-a
        destinations:
          - stack-a
    defaultDestinations:
      - platform

podLogsViaOpenTelemetry:
  enabled: true
  destinations:
    - tenantRouter
```

## Configuration reference

A router destination supports the following fields:

-   `attribute` (string, defaults to `k8s.namespace.name`) - the attribute whose value decides
    routing. It must start with a letter or underscore and contain only letters, digits,
    underscores, dots, slashes, and hyphens.
-   `routes` (list) - an ordered list of routing rules. Each entry has:
    -   `match` - exactly one of `equals`, `in`, or `matches`:
        -   `equals` (string) - the attribute value must equal this string.
        -   `in` (list of strings) - the attribute value must equal one of these strings.
        -   `matches` (string) - the attribute value must match this pattern (see
            [Pattern matching](#pattern-matching), below).
    -   `destinations` (list of strings, required, at least one entry) - the real destination(s) to
        send a matching record to.
    -   `signals` (list, optional) - restricts this route to a subset of `metrics`, `logs`,
        `traces`, `profiles`. When absent, the route applies to every signal.
-   `defaultDestinations` (list of strings, **mandatory**, at least one entry) - the destination(s)
    for records that don't match any route.

## Semantics

Routes are evaluated in the order they're declared, and the first matching route wins for each
signal. A router is a terminal destination: it never talks to a real backend itself, so it
requires at least one entry in `defaultDestinations` for records that fall through every route (or
that match a route whose `destinations` don't carry the signal being routed). A record is sent to
exactly one set of destinations per signal, either the matched route's `destinations` or
`defaultDestinations`. There's no combining a route's destinations with the default; matching is
exclusive.

## Routing happens on the collection pipeline, not the destination

Where a record enters the pipeline decides whether it can route on the router's `attribute` at
all, independent of where the record is ultimately sent. Scraped metrics, Loki pod logs, and
Pyroscope profiles are routed on the mapped label before anything is converted to OpenTelemetry
Protocol, even when the matched destination happens to be an OpenTelemetry Protocol destination.
Only telemetry that's collected via OpenTelemetry Protocol from the start (for example,
`podLogsViaOpenTelemetry`, `applicationObservability`) can route on an arbitrary attribute.

The `attribute` field maps to a label as follows:

-   `k8s.namespace.name` (the default) maps to the `namespace` label.
-   Any other attribute that is itself a valid Prometheus label name (letters, digits, and
    underscores only, starting with a letter or underscore) is used as that label name.
-   Any other attribute has no label equivalent. On the scraped-metrics, Loki, and Pyroscope
    collection pipelines, routing on that attribute falls through to `defaultDestinations` for
    every record, and the chart emits a warning (`W-a`) at render time to flag this. The
    OpenTelemetry Protocol collection pipeline is unaffected, because it routes on the attribute
    directly.

## Explicit opt-in is required

Routers are excluded from a feature's implicit destination selection. If a feature has no
`destinations` list of its own, the chart never picks a router for it automatically, even if the
router is the only destination that would otherwise qualify. Every feature that should send
telemetry through a router must list that router by name:

```yaml
podLogsViaOpenTelemetry:
  enabled: true
  destinations:
    - tenantRouter
```

The chart emits a warning at render time when a router is configured but at least one enabled
feature has no explicit `destinations` list, since that feature won't use the router.

## Pattern matching

`match.equals` and `match.in` compare against literal strings: any pattern metacharacters in the
values are escaped before being used for comparison, so a value like `team.a` matches only the
literal string `team.a`. `match.matches`, by contrast, is a pattern: its value is used as-is, so a
value like `^team-.*-canary$` matches any string with that shape.

The implementation differs by collection pipeline, and `match.matches` is not anchored the same
way on every pipeline:

-   On the label-based pipelines (scraped metrics, Loki, Pyroscope), the router builds an anchored
    pattern for `equals`/`in`, and the underlying label-matching mechanism always anchors the
    whole value (Prometheus semantics) -- including for `matches`, so the pattern must match the
    entire label value, not part of it.
-   On the OpenTelemetry Protocol pipeline, `equals` and `in` become exact string comparisons
    (`in` becomes an OR-chain of comparisons, since the underlying transform language has no
    native list-membership operator), and `matches` is passed to that language's pattern-matching
    function, which matches anywhere within the attribute value rather than anchoring to the whole
    string. All values are escaped for the string-literal context they're spliced into.

Because of this difference, write `match.matches` patterns fully anchored (`^...$`) so they
behave consistently across every collection pipeline.

## Router-to-router isn't supported

A route or `defaultDestinations` entry can't point at another router destination. Chaining routers
would wire one router's fan-out into another router's inputs, forming a cycle in the generated
Alloy pipeline, so the chart fails the render with a clear error message.

## Scaling

Each real destination a router can reach adds one Alloy component gate per downstream per signal,
so the number of generated components grows about linearly with the number of destinations a
router fans out to (across whichever signals actually flow through it). A router that only ever
sees one signal, or that fans out to a small number of destinations, stays cheap; a router that
fans out to many destinations across every signal generates proportionally more Alloy components.

## Worked examples

### Example 1: OpenTelemetry Protocol tenant-per-namespace

Application traces and logs collected via OpenTelemetry Protocol are split by tenant namespace,
with every other namespace landing on a shared platform destination:

```yaml
destinations:
  platform:
    type: otlp
    url: http://tempo-platform.tempo.svc:443/otlp
  stack-a:
    type: otlp
    url: http://tempo-stack-a.tempo.svc:443/otlp
  stack-b:
    type: otlp
    url: http://tempo-stack-b.tempo.svc:443/otlp
  tenantRouter:
    type: router
    routes:
      - match:
          equals: tenant-a
        destinations:
          - stack-a
      - match:
          in:
            - tenant-b
            - tenant-b-canary
        destinations:
          - stack-b
    defaultDestinations:
      - platform

applicationObservability:
  enabled: true
  destinations:
    - tenantRouter
```

A record whose `k8s.namespace.name` resource attribute is `tenant-a` goes to `stack-a`. A record
from `tenant-b` or `tenant-b-canary` goes to `stack-b`. Every other record goes to `platform`.

### Example 2: mixed Prometheus, Loki, and OpenTelemetry Protocol, per-signal

A single router serves scraped cluster metrics, Loki pod logs, and OpenTelemetry Protocol traces
at once, with different destinations and a per-route `signals` restriction:

```yaml
destinations:
  mimir:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
  tempo:
    type: otlp
    url: http://tempo.tempo.svc:443/otlp
  team-router:
    type: router
    attribute: team
    routes:
      - match:
          equals: checkout
        destinations:
          - mimir
          - loki
        signals:
          - metrics
          - logs
      - match:
          equals: payments
        destinations:
          - tempo
        signals:
          - traces
    defaultDestinations:
      - mimir
      - loki

clusterMetrics:
  enabled: true
  destinations:
    - team-router

podLogsViaLoki:
  enabled: true
  destinations:
    - team-router

applicationObservability:
  enabled: true
  destinations:
    - team-router
```

Here `attribute: team` is dot-free and matches the Prometheus label-name grammar, so it's usable
as a label on the scraped-metrics and Loki pipelines as well as an attribute on the OpenTelemetry
Protocol pipeline. Cluster metrics and pod logs tagged `team: checkout` go to `mimir` and `loki`
respectively; traces tagged `team: payments` go to `tempo`; everything else falls back to
`mimir`/`loki` for the signals those destinations carry.
