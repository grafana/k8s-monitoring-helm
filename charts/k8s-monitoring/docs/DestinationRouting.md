# Destination routing

The `router` destination type sends telemetry to different real destinations based on a route table
of match conditions evaluated against each record, all from a single release. This is useful for
splitting telemetry by tenant, team, or environment without deploying a separate collector or
release per group.

## What a router is

A router is not a telemetry backend. It never receives a URL, credentials, or a protocol. It is a
virtual destination: a named entry under `destinations` with `type: router` that a feature points
at the same way it would point at any other destination, by listing its name in that feature's
`destinations`. When a record reaches the router, the router evaluates its route table, decides
which real destination(s) the record should go to, and forwards it there.

Every router declares an `ecosystem`, which names the collection pipeline it routes and fixes how
its conditions are written:

-   `otlp` routes OpenTelemetry Protocol data (metrics, logs, and traces) by matching **resource
    attributes** with OTTL.
-   `prometheus`, `loki`, and `pyroscope` route the corresponding label-based pipeline (scraped
    metrics, Loki logs, and Pyroscope profiles respectively) by matching **labels** with relabel
    rules.

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
    ecosystem: otlp
    routes:
      - match:
          - resourceAttribute: k8s.namespace.name
            op: equals
            value: tenant-a
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

-   `ecosystem` (string, **mandatory**) - one of `otlp`, `prometheus`, `loki`, or `pyroscope`. Names
    the collection pipeline the router routes, which decides how each condition is written and which
    features can use it.
-   `routes` (list) - an ordered list of routing rules. Each entry has:
    -   `match` (list, required, at least one entry) - a list of conditions that are ANDed together;
        the route matches only when every condition matches. Each condition has:
        -   `resourceAttribute: <name>` (for an `otlp` router) - the OpenTelemetry resource attribute
            to match on, **or** `label: <name>` (for a `prometheus`/`loki`/`pyroscope` router) - the
            label to match on. The condition's key must match the router's `ecosystem`.
        -   `op` - one of `equals`, `notEquals`, `in`, `matches`, `notMatches`. `notEquals` and
            `notMatches` are `otlp`-only (the relabel pipelines can only keep, not exclude); a
            label-based route can only use `matches` when it is the route's single condition.
        -   `value` - a string, or (for `op: in`) a non-empty list of strings.
    -   `destinations` (list of strings, required, at least one entry) - the real destination(s) to
        send a matching record to.
    -   `signals` (list, optional) - restricts this route to a subset of the signals the ecosystem
        routes (`metrics`, `logs`, `traces` for `otlp`; the single signal for the others). When
        absent, the route applies to every signal the ecosystem routes.
-   `defaultDestinations` (list of strings, **mandatory**, at least one entry) - the destination(s)
    for records that don't match any route.

## Ecosystems and collection pipelines

Where a record is collected -- not where it is ultimately sent -- decides which ecosystem can route
it. Scraped metrics, Loki pod logs, and Pyroscope profiles are routed on labels; OpenTelemetry
Protocol data is routed on resource attributes with OTTL. These are separate mechanisms, and each is
its own signal-specific pipeline, so a router serves exactly one:

| router `ecosystem` | serves features collecting via | signals | matches on |
|--------------------|--------------------------------|---------|------------|
| `otlp`             | OpenTelemetry Protocol (`podLogsViaOpenTelemetry`, `applicationObservability`, …) | metrics, logs, traces | `resourceAttribute` |
| `prometheus`       | scraped Prometheus metrics (`clusterMetrics`, `annotationAutodiscovery`, …)       | metrics | `label` |
| `loki`             | Loki logs (`podLogsViaLoki`, `clusterEvents`, …)                                  | logs | `label` |
| `pyroscope`        | Pyroscope profiles (`profiling`, …)                                               | profiles | `label` |

A feature may only route through a router whose ecosystem matches the pipeline that feature collects
on. If a feature forwards a signal to a router of the wrong ecosystem, the chart fails the render
with a clear error rather than silently dropping the record. Likewise, every destination a router
fans out to (in a route or in `defaultDestinations`) must support the signal the ecosystem routes --
pointing a `pyroscope` router at a metrics-only destination, for example, fails the render. Traces
(Tempo) are always collected via the OpenTelemetry Protocol, so they route through an `otlp` router;
there is no label-based trace routing.

To split the same telemetry across pipelines -- for example scraped metrics *and* OTLP traces -- use
one router per ecosystem and point each feature at the matching one (see Example 2).

## Semantics

Routes are evaluated in the order they're declared, and the first matching route wins for each
signal. A router is a terminal destination: it never talks to a real backend itself, so it requires
at least one entry in `defaultDestinations` for records that fall through every route (or that match
a route whose `destinations` don't carry the signal being routed). A record is sent to exactly one
set of destinations per signal, either the matched route's `destinations` or `defaultDestinations`.
There's no combining a route's destinations with the default; matching is exclusive.

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

`op: equals`/`op: notEquals` and `op: in` compare against literal strings: any pattern
metacharacters in the values are escaped before being used for comparison, so a value like `team.a`
matches only the literal string `team.a`. `op: matches`/`op: notMatches`, by contrast, take a
pattern: the value is used as-is, so a value like `^team-.*-canary$` matches any string with that
shape.

The implementation differs by ecosystem, and `matches` is not anchored the same way:

-   On a `prometheus`/`loki`/`pyroscope` router, the router builds an anchored pattern for
    `equals`/`in`, and the underlying label-matching mechanism always anchors the whole value
    (Prometheus semantics) -- including for `matches`, so the pattern must match the entire label
    value. These pipelines can only keep matching records, so `notEquals`/`notMatches` are not
    available; and a route that combines conditions joins their labels with a separator, which a
    regular expression `matches` cannot participate in, so `matches` must be a route's only
    condition.
-   On an `otlp` router, `equals`/`notEquals` become exact string comparisons, `in` becomes an
    OR-chain of comparisons (OTTL has no native list-membership operator), and `matches`/`notMatches`
    are passed to OTTL's `IsMatch`, which matches anywhere within the attribute value rather than
    anchoring to the whole string. All values are escaped for the string-literal context they're
    spliced into.

Because of this difference, write `matches` patterns fully anchored (`^...$`) so they behave
consistently across both ecosystems.

## Router-to-router isn't supported

A route or `defaultDestinations` entry can't point at another router destination. Chaining routers
would wire one router's fan-out into another router's inputs, forming a cycle in the generated Alloy
pipeline, so the chart fails the render with a clear error message.

## Scaling

Each real destination a router can reach adds one Alloy component gate per downstream per signal, so
the number of generated components grows about linearly with the number of destinations a router
fans out to (across whichever signals actually flow through it). A router that only ever sees one
signal, or that fans out to a small number of destinations, stays cheap; a router that fans out to
many destinations across every signal generates proportionally more Alloy components.

## Worked examples

### Example 1: OpenTelemetry Protocol tenant-per-namespace

Application traces and logs collected via OpenTelemetry Protocol are split by tenant namespace, with
every other namespace landing on a shared platform destination:

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
    ecosystem: otlp
    routes:
      - match:
          - resourceAttribute: k8s.namespace.name
            op: equals
            value: tenant-a
        destinations:
          - stack-a
      - match:
          - resourceAttribute: k8s.namespace.name
            op: in
            value:
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

### Example 2: one router per ecosystem

A router serves exactly one collection ecosystem, so routing scraped metrics, Loki logs, and OTLP
traces at once means one router per ecosystem, each pointed at by the matching feature:

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

  metricsRouter:
    type: router
    ecosystem: prometheus
    routes:
      - match:
          - label: namespace
            op: equals
            value: checkout
        destinations: [mimir]
    defaultDestinations: [mimir]

  logsRouter:
    type: router
    ecosystem: loki
    routes:
      - match:
          - label: namespace
            op: equals
            value: checkout
        destinations: [loki]
    defaultDestinations: [loki]

  traceRouter:
    type: router
    ecosystem: otlp
    routes:
      - match:
          - resourceAttribute: k8s.namespace.name
            op: equals
            value: payments
        destinations: [tempo]
    defaultDestinations: [tempo]

clusterMetrics:
  enabled: true
  destinations:
    - metricsRouter

podLogsViaLoki:
  enabled: true
  destinations:
    - logsRouter

applicationObservability:
  enabled: true
  destinations:
    - traceRouter
```

`metricsRouter` and `logsRouter` match the `namespace` label on the scraped-metrics and Loki
pipelines; metrics and logs from the `checkout` namespace go to `mimir` and `loki` respectively,
and everything else falls back to the same defaults. `traceRouter` matches the `k8s.namespace.name`
resource attribute on the OpenTelemetry Protocol pipeline; traces from the `payments` namespace go
to `tempo`. Pointing `clusterMetrics` at `logsRouter` or `traceRouter` (or any feature at a router
of a different ecosystem) fails the render.
