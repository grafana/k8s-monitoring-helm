{{- /* Validates a `router` destination (see destinations/router-values.yaml and
       _destination_router.tpl for what this feeds). A router is a virtual destination: it never
       talks to a backend itself, it only fans telemetry out to real downstream destinations. That
       means its validation has to reach outside its own destination block into the full
       destinations map, to confirm every reference it makes (routes[].destinations,
       defaultDestinations) actually exists, is enabled, and isn't itself another router. */}}
{{- /* Inputs: Values (root context -- the object destinations.validate itself was called with,
       i.e. `$` from inside its enclosing range over destinations, NOT the chart's `.Values` map.
       So `.Values.Values` here is the chart's actual `.Values`, and `.Values.Values.destinations`
       is the full destinations map. This is required because, unlike otlp validation, router
       validation needs to look up destinations besides its own.), Destination (a router
       Destination), DestinationName (the destination's name) */}}
{{- define "destinations.router.validate" }}
  {{- $name := .DestinationName }}
  {{- $router := .Destination }}
  {{- $root := .Values }}
  {{- $allDestinations := .Values.Values.destinations | default dict }}
  {{- $enabledDestinations := include "destinations.getEnabled" $allDestinations | fromYaml }}
  {{- /* Minor (a): routers aren't valid route/defaultDestinations targets (R8 below already
         forbids referencing one), so don't suggest them in R6's "known destinations" list. */}}
  {{- $knownDestinationNames := list }}
  {{- range $k, $v := $enabledDestinations }}
    {{- if ne $v.type "router" }}{{- $knownDestinationNames = append $knownDestinationNames $k }}{{- end }}
  {{- end }}
  {{- $knownDestinationNames = $knownDestinationNames | sortAlpha }}
  {{- $routes := $router.routes | default list }}
  {{- $defaultDestinations := $router.defaultDestinations | default list }}

  {{- /* R0: `attribute` (defaults to k8s.namespace.name when unset) must be a syntactically
         valid attribute name: non-empty, starting with a letter/underscore, containing only
         letters/digits/underscore/dot/slash/hyphen, and critically no quotes, backticks,
         backslashes, or whitespace. destinations.router.ottlCondition splices this value
         unquoted into `attributes["<attribute>"]`, so anything outside this grammar (e.g.
         `foo"] == "x`) would let user input break out of the OTTL string literal and inject
         arbitrary OTTL/Alloy syntax. */}}
  {{- $attribute := $router.attribute | default "k8s.namespace.name" }}
  {{- if not (regexMatch "^[a-zA-Z_][a-zA-Z0-9_./-]*$" $attribute) }}
    {{- $msg := list "" (printf "Destination \"%s\" (type: router) has an invalid attribute: %q." $name $attribute) }}
    {{- $msg = append $msg "Please use a valid attribute name." }}
    {{- $msg = append $msg "It must start with a letter or underscore and contain only letters, digits, underscores, dots, slashes, and hyphens -- no quotes, backticks, backslashes, or whitespace." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "destinations:" }}
    {{- $msg = append $msg (printf "  %s:" $name) }}
    {{- $msg = append $msg "    type: router" }}
    {{- $msg = append $msg "    attribute: k8s.namespace.name" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- /* R1: defaultDestinations is mandatory. A router is a terminal destination: records that
         don't match any route (or match a route that doesn't cover their signal) fall back to
         defaultDestinations, so unmatched telemetry always needs somewhere to land. */}}
  {{- if empty $defaultDestinations }}
    {{- $msg := list "" (printf "Destination \"%s\" (type: router) does not have any defaultDestinations." $name) }}
    {{- $msg = append $msg "A router is a terminal destination, so it must name at least one fallback destination for records that don't match any route." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "destinations:" }}
    {{- $msg = append $msg (printf "  %s:" $name) }}
    {{- $msg = append $msg "    type: router" }}
    {{- $msg = append $msg "    defaultDestinations:" }}
    {{- $msg = append $msg "      - my-destination" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- range $i, $route := $routes }}
    {{- $routeNum := add1 $i }}
    {{- $match := $route.match | default dict }}
    {{- $matchKeys := list }}
    {{- range $k := list "equals" "in" "matches" }}
      {{- if hasKey $match $k }}{{- $matchKeys = append $matchKeys $k }}{{- end }}
    {{- end }}

    {{- /* R2: exactly one of equals/in/matches. */}}
    {{- if eq (len $matchKeys) 0 }}
      {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) with no match condition." $name $routeNum) }}
      {{- $msg = append $msg "Every route must set exactly one of match.equals, match.in, or match.matches." }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "destinations:" }}
      {{- $msg = append $msg (printf "  %s:" $name) }}
      {{- $msg = append $msg "    type: router" }}
      {{- $msg = append $msg "    routes:" }}
      {{- $msg = append $msg "      - match:" }}
      {{- $msg = append $msg "          equals: my-value" }}
      {{- $msg = append $msg "        destinations:" }}
      {{- $msg = append $msg "          - my-destination" }}
      {{- fail (join "\n" $msg) }}
    {{- else if gt (len $matchKeys) 1 }}
      {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) with multiple match conditions set: %s." $name $routeNum (join ", " $matchKeys)) }}
      {{- $msg = append $msg "Exactly one of match.equals, match.in, or match.matches is required per route." }}
      {{- $msg = append $msg "Please remove all but one of these fields." }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- /* R2b: `in` must be a list. A scalar value here (e.g. `in: foo` parsed as a YAML string)
           passes the schema's `oneOf` required-key check and R3's `empty` check below (a
           non-empty string is not "empty"), but R4's and the body's `range $v := $match.in` over
           a plain string is not supported by Go's text/template range action, so it fails render
           with a raw, confusing "range can't iterate over ..." error. Catch it here, before any
           range over match.in, with a clear message instead. */}}
    {{- if and (hasKey $match "in") (not (kindIs "slice" $match.in)) }}
      {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) whose match.in value is not a list: %v." $name $routeNum $match.in) }}
      {{- $msg = append $msg "The `in` match must be a list, e.g. `in: [value1, value2]`." }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "destinations:" }}
      {{- $msg = append $msg (printf "  %s:" $name) }}
      {{- $msg = append $msg "    type: router" }}
      {{- $msg = append $msg "    routes:" }}
      {{- $msg = append $msg "      - match:" }}
      {{- $msg = append $msg "          in: [my-value-a, my-value-b]" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- /* R3: `in` must be non-empty. Only reachable when it's the sole match key (R2 already
           failed on zero or multiple match keys). */}}
    {{- if and (hasKey $match "in") (empty $match.in) }}
      {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) with an empty match.in list." $name $routeNum) }}
      {{- $msg = append $msg "match.in needs at least one value to match against." }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "destinations:" }}
      {{- $msg = append $msg (printf "  %s:" $name) }}
      {{- $msg = append $msg "    type: router" }}
      {{- $msg = append $msg "    routes:" }}
      {{- $msg = append $msg "      - match:" }}
      {{- $msg = append $msg "          in: [my-value-a, my-value-b]" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- /* R4: match values must be strings. They get spliced into a regex (equals/in, via
           regexQuoteMeta) or used verbatim as a regex (matches), so a YAML value parsed as a
           bool/number/null (e.g. an unquoted `true` or `123`) is very likely not what the user
           meant to match against. */}}
    {{- if hasKey $match "equals" }}
      {{- if not (kindIs "string" $match.equals) }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) whose match.equals value is not a string: %v." $name $routeNum $match.equals) }}
        {{- $msg = append $msg "Please quote it so it isn't parsed as a YAML number, boolean, or null:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  %s:" $name) }}
        {{- $msg = append $msg "    type: router" }}
        {{- $msg = append $msg "    routes:" }}
        {{- $msg = append $msg "      - match:" }}
        {{- $msg = append $msg (printf "          equals: \"%v\"" $match.equals) }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
    {{- end }}
    {{- if hasKey $match "in" }}
      {{- range $v := $match.in }}
        {{- if not (kindIs "string" $v) }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) whose match.in list contains a non-string value: %v." $name $routeNum $v) }}
          {{- $msg = append $msg "Please quote it so it isn't parsed as a YAML number, boolean, or null:" }}
          {{- $msg = append $msg "destinations:" }}
          {{- $msg = append $msg (printf "  %s:" $name) }}
          {{- $msg = append $msg "    type: router" }}
          {{- $msg = append $msg "    routes:" }}
          {{- $msg = append $msg "      - match:" }}
          {{- $msg = append $msg (printf "          in: [\"%v\"]" $v) }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- if hasKey $match "matches" }}
      {{- if not (kindIs "string" $match.matches) }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) whose match.matches value is not a string: %v." $name $routeNum $match.matches) }}
        {{- $msg = append $msg "Please quote it so it isn't parsed as a YAML number, boolean, or null:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  %s:" $name) }}
        {{- $msg = append $msg "    type: router" }}
        {{- $msg = append $msg "    routes:" }}
        {{- $msg = append $msg "      - match:" }}
        {{- $msg = append $msg (printf "          matches: \"%v\"" $match.matches) }}
        {{- fail (join "\n" $msg) }}
      {{- end }}

      {{- /* R5: matches must compile as a regex. mustRegexMatch fails the template with Go's
             regexp compile error if it doesn't, which is acceptable here: the body
             (destinations.router.ottlCondition / matchRegex) uses this same string as a regex, so
             a compile error here is exactly the error the user needs to see. */}}
      {{- $_ := mustRegexMatch $match.matches "" }}
    {{- end }}

    {{- /* R5b: every route must have at least one destination. An empty or missing destinations
           list would pass every other check yet silently blackhole every record that matches
           this route (the router body would stamp/select an empty destination list for it, so
           the record matches no downstream gate for any signal and simply vanishes instead of
           falling back to defaultDestinations). */}}
    {{- if empty ($route.destinations | default list) }}
      {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) with an empty or missing destinations list." $name $routeNum) }}
      {{- $msg = append $msg "A route with no destinations would silently drop every record that matches it." }}
      {{- $msg = append $msg "Please set at least one destination:" }}
      {{- $msg = append $msg "destinations:" }}
      {{- $msg = append $msg (printf "  %s:" $name) }}
      {{- $msg = append $msg "    type: router" }}
      {{- $msg = append $msg "    routes:" }}
      {{- $msg = append $msg "      - match:" }}
      {{- $msg = append $msg "          equals: my-value" }}
      {{- $msg = append $msg "        destinations:" }}
      {{- $msg = append $msg "          - my-destination" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- /* R6 (route destinations): every referenced destination must exist and be enabled. */}}
    {{- $routeDestinations := $route.destinations | default list }}
    {{- range $d := $routeDestinations }}
      {{- if not (hasKey $enabledDestinations $d) }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) referencing unknown destination \"%s\"." $name $routeNum $d) }}
        {{- $msg = append $msg "The destination must exist and be enabled." }}
        {{- $msg = append $msg "Please reference one of the known destinations:" }}
        {{- range $k := $knownDestinationNames }}{{- $msg = append $msg (printf "  %s" $k) }}{{- end }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
    {{- end }}

    {{- /* R7: signals (when present) must be non-empty and only contain known signal names. */}}
    {{- if hasKey $route "signals" }}
      {{- if empty $route.signals }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) with an empty signals list." $name $routeNum) }}
        {{- $msg = append $msg "Either remove the signals field to match all signals, or list at least one of: metrics, logs, traces, profiles." }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
      {{- range $s := $route.signals }}
        {{- if not (has $s (list "metrics" "logs" "traces" "profiles")) }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) with an unknown signal \"%s\"." $name $routeNum $s) }}
          {{- $msg = append $msg "Please use one of: metrics, logs, traces, profiles." }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- /* R8 (cycle, route destinations): a route must not point at another router. Chaining
           routers would try to wire one router's fan-out gates into another router's OTTL/label
           inputs, which _destination_router.tpl does not support and would form a cycle in the
           generated Alloy pipeline. */}}
    {{- range $d := $routeDestinations }}
      {{- if hasKey $enabledDestinations $d }}
        {{- if eq (get $enabledDestinations $d).type "router" }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) referencing another router destination \"%s\"." $name $routeNum $d) }}
          {{- $msg = append $msg "Routing telemetry from one router into another router would create a cycle in the generated Alloy pipeline, so it is not supported." }}
          {{- $msg = append $msg "Please point routes and defaultDestinations at real (non-router) destinations." }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* R6 (defaultDestinations): every default destination must exist and be enabled. */}}
  {{- range $d := $defaultDestinations }}
    {{- if not (hasKey $enabledDestinations $d) }}
      {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a defaultDestinations entry referencing unknown destination \"%s\"." $name $d) }}
      {{- $msg = append $msg "The destination must exist and be enabled." }}
      {{- $msg = append $msg "Please reference one of the known destinations:" }}
      {{- range $k := $knownDestinationNames }}{{- $msg = append $msg (printf "  %s" $k) }}{{- end }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}

  {{- /* R8 (cycle, defaultDestinations): same cycle guard as routes, above. */}}
  {{- range $d := $defaultDestinations }}
    {{- if hasKey $enabledDestinations $d }}
      {{- if eq (get $enabledDestinations $d).type "router" }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a defaultDestinations entry referencing another router destination \"%s\"." $name $d) }}
        {{- $msg = append $msg "Routing telemetry from one router into another router would create a cycle in the generated Alloy pipeline, so it is not supported." }}
        {{- $msg = append $msg "Please point routes and defaultDestinations at real (non-router) destinations." }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* R10 (defaultDestinations signal coverage) used to hard-fail here by INFERRING which
         signals were "in play" on the router (all four when it had no routes). That inference
         was a false positive generator: a no-routes fan-out router with e.g. otlp
         defaultDestinations would fail on "profiles" (otlp can't carry profiles) even when the
         only feature actually using the router sends logs. The router itself has no way to know
         which signals a feature will actually forward through it -- only the forwarding seam
         does. See destinations.router.assertCanCarry below, invoked from
         pipeline.alloy.targets.forFeature (templates/dataProcessors/_config.alloy.tpl) once per
         (feature, type, ecosystem) a feature actually emits, which is where "signal actually
         sent" and "router capability" can be checked together without guessing. */}}

  {{- /* R9 (unsupported-signal warning, deliberately not a hard failure here): a route can
         legitimately mix downstreams that don't all support the same signals -- e.g. a route with
         no `signals` filter pointing at both a metrics+logs destination and a traces-only
         destination is a normal way to fan out mixed telemetry. destinations.router.alloy already
         handles this per-signal (destinations.router.downstreamForSignal drops a downstream from a
         signal's forward_to/output list when it doesn't support that signal), so silently dropping
         is correct behavior, not a bug -- but it's a rendering step the user should still be
         warned about. That warning belongs in the destinations.notes mechanism (Phase 4), not
         here: hard-failing would make legitimate mixed-signal routing impossible. See
         destinations.router.notes below, wired into NOTES.txt via destinations.notes.router. */}}
{{- end }}

{{/* Precise, false-positive-free replacement for the old R10 inference: asserts that a router
     destination can actually deliver ONE signal a feature is ACTUALLY forwarding to it. Invoked
     from pipeline.alloy.targets.forFeature (templates/dataProcessors/_config.alloy.tpl) once per
     (feature, type, ecosystem) tuple the feature emits, and only when a router destination is
     among that tuple's resolved destinationNames -- this is the only place in the chart where a
     feature's real per-destination signal is known, so it is the only place this check can be
     both correct (never fires for a signal the feature doesn't send) and complete (always fires
     for a signal the feature does send that would be dropped).

     Capability mirrors destinations.router.downstreamForSignal / the router body exactly: the
     router can carry `.type` if defaultDestinations has an entry that supports `.type`, OR any
     route that covers `.type` (no `signals` filter, or `signals` includes `.type`) has a
     destination that supports `.type`. A route that does NOT cover `.type` is irrelevant --
     records of this signal never match it in the body (destinations.router.alloy's per-signal
     labelRules/ottlStatements only emit a rule for a route when the route covers that signal),
     so its destinations' capability for `.type` is not this check's concern.

     Inputs: root (full Values, i.e. `.root` from pipeline.alloy.targets.forFeature),
     featureKey (string), routerName (string, a destinations key already confirmed to be
     type: router by the caller), type (metrics|logs|traces|profiles). */}}
{{- define "destinations.router.assertCanCarry" }}
  {{- $root := .root }}
  {{- $featureKey := .featureKey }}
  {{- $routerName := .routerName }}
  {{- $type := .type }}
  {{- $allDestinations := $root.Values.destinations | default dict }}
  {{- $enabledDestinations := include "destinations.getEnabled" $allDestinations | fromYaml }}
  {{- $router := get $enabledDestinations $routerName }}
  {{- $routes := $router.routes | default list }}
  {{- $defaultDestinations := $router.defaultDestinations | default list }}

  {{- /* Union of every destination this router can ever send to (routes[].destinations +
         defaultDestinations), same as destinations.router.alloy's $allDownstream. */}}
  {{- $allDownstream := list }}
  {{- range $d := $defaultDestinations }}
    {{- if not (has $d $allDownstream) }}{{- $allDownstream = append $allDownstream $d }}{{- end }}
  {{- end }}
  {{- range $route := $routes }}
    {{- range $d := ($route.destinations | default list) }}
      {{- if not (has $d $allDownstream) }}{{- $allDownstream = append $allDownstream $d }}{{- end }}
    {{- end }}
  {{- end }}

  {{- /* Resolve each downstream's type + fully-merged-with-defaults values once, same as
         destinations.router.alloy's $downstreamInfo. Every name here has already been confirmed
         (by destinations.router.validate's R6/R8 checks) to exist, be enabled, and not be a
         router. */}}
  {{- $downstreamInfo := dict }}
  {{- range $d := $allDownstream }}
    {{- if hasKey $enabledDestinations $d }}
      {{- $dest := get $enabledDestinations $d }}
      {{- $defaults := (printf "destinations/%s-values.yaml" $dest.type) | $root.Files.Get | fromYaml }}
      {{- $merged := mergeOverwrite $defaults $dest }}
      {{- $_ := set $downstreamInfo $d (dict "type" $dest.type "values" $merged) }}
    {{- end }}
  {{- end }}

  {{- $capable := false }}
  {{- $defaultCovered := include "destinations.router.downstreamForSignal" (dict "allDownstream" $defaultDestinations "downstreamInfo" $downstreamInfo "signal" $type) | fromYamlArray }}
  {{- if not (empty $defaultCovered) }}
    {{- $capable = true }}
  {{- end }}
  {{- if not $capable }}
    {{- range $route := $routes }}
      {{- if or (not (hasKey $route "signals")) (has $type $route.signals) }}
        {{- $routeDestinations := $route.destinations | default list }}
        {{- $routeCovered := include "destinations.router.downstreamForSignal" (dict "allDownstream" $routeDestinations "downstreamInfo" $downstreamInfo "signal" $type) | fromYamlArray }}
        {{- if not (empty $routeCovered) }}
          {{- $capable = true }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if not $capable }}
    {{- $msg := list "" (printf "Feature \"%s\" sends %s to router destination \"%s\", but that router has no route or defaultDestinations entry that can accept %s." $featureKey $type $routerName $type) }}
    {{- $msg = append $msg (printf "%s reaching this router would be dropped." $type) }}
    {{- $msg = append $msg (printf "Please add a destination that supports %s to the router's routes or defaultDestinations." $type) }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}

{{/* Phase 4: soft, render-time warnings for a single enabled router destination. Telemetry still
     flows in every case this covers (it falls back to defaultDestinations), so these are notes,
     not validation failures -- see R9 above for why. Invoked once per enabled router destination
     from destinations.notes.router (_destination_notes.tpl). This define assumes valid input:
     destinations.router.validate has already run and rejected malformed attributes/routes. */}}
{{- /* Inputs: Values (root context, same convention as destinations.router.validate above),
       Destination (a router Destination), DestinationName (the destination's name) */}}
{{- define "destinations.router.notes" }}
  {{- $root := .Values }}
  {{- $name := .DestinationName }}
  {{- $router := .Destination }}
  {{- $allDestinations := $root.Values.destinations | default dict }}
  {{- $enabledDestinations := include "destinations.getEnabled" $allDestinations | fromYaml }}
  {{- $attribute := $router.attribute | default "k8s.namespace.name" }}
  {{- $routes := $router.routes | default list }}
  {{- $defaultDestinations := $router.defaultDestinations | default list }}

  {{- /* W-a: the attribute has no valid Prometheus/Loki/Pyroscope label equivalent (same
         promotion rule as the body's $labelName in destinations.router.alloy). On those
         label-based collection pipelines, routing is applied before any OTLP conversion could
         happen, so an attribute that can't become a label falls through to defaultDestinations
         on those ecosystems even if the matched downstream is itself an OTLP destination -- only
         telemetry that is actually collected via OTLP can route on an arbitrary attribute. */}}
  {{- if and (ne $attribute "k8s.namespace.name") (not (regexMatch "^[a-zA-Z_][a-zA-Z0-9_]*$" $attribute)) }}

WARNING: Router "{{ $name }}" routes on attribute "{{ $attribute }}", which is not "k8s.namespace.name" and does not match the Prometheus/Loki/Pyroscope label-name grammar (^[a-zA-Z_][a-zA-Z0-9_]*$), so it has no valid label equivalent. On the Prometheus, Loki, and Pyroscope collection pipelines (scraped metrics, Loki pod logs, Pyroscope profiles), routing on "{{ $attribute }}" falls through to defaultDestinations -- even when the matched destination is OTLP -- because routing is applied on the collection pipeline before any OTLP conversion; only OTLP-collected telemetry can route on an arbitrary attribute.
  {{- end }}

  {{- /* W-b: for each route, for each signal it covers, warn if NONE of its destinations support
         that signal. Computed the same way destinations.router.alloy computes it
         (downstreamForSignal / supports_<signal>), so this fires exactly when the F5 fallback
         kicks in for that route/signal. */}}
  {{- $allDownstream := list }}
  {{- range $d := $defaultDestinations }}
    {{- if not (has $d $allDownstream) }}{{- $allDownstream = append $allDownstream $d }}{{- end }}
  {{- end }}
  {{- range $route := $routes }}
    {{- range $d := ($route.destinations | default list) }}
      {{- if not (has $d $allDownstream) }}{{- $allDownstream = append $allDownstream $d }}{{- end }}
    {{- end }}
  {{- end }}
  {{- $downstreamInfo := dict }}
  {{- range $d := $allDownstream }}
    {{- if hasKey $enabledDestinations $d }}
      {{- $dest := get $enabledDestinations $d }}
      {{- $defaults := (printf "destinations/%s-values.yaml" $dest.type) | $root.Files.Get | fromYaml }}
      {{- $merged := mergeOverwrite $defaults $dest }}
      {{- $_ := set $downstreamInfo $d (dict "type" $dest.type "values" $merged) }}
    {{- end }}
  {{- end }}
  {{- range $i, $route := $routes }}
    {{- $routeNum := add1 $i }}
    {{- $routeDestinations := $route.destinations | default list }}
    {{- $signals := $route.signals | default (list "metrics" "logs" "traces" "profiles") }}
    {{- range $signal := $signals }}
      {{- $covered := include "destinations.router.downstreamForSignal" (dict "allDownstream" $routeDestinations "downstreamInfo" $downstreamInfo "signal" $signal) | fromYamlArray }}
      {{- if empty $covered }}

WARNING: Router "{{ $name }}" route #{{ $routeNum }} covers the "{{ $signal }}" signal, but none of its destinations support {{ $signal }}. Matched {{ $signal }} for this route falls back to defaultDestinations.
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* W-b2 (defaultDestinations signal coverage) used to be warned about here, but is now a
         hard install-time failure enforced in destinations.router.validate (R10, above) -- a
         router is terminal, so a signal in play here with no capable defaultDestinations is a
         genuine silent drop, not something that should only be surfaced as a NOTES.txt warning.
         Install fails before notes render, so this note would be dead code; see R10's comment for
         the full rationale (in-play-signal inference, why supports_<signal> is unconditionally
         true for a router, etc.). */}}
{{- end }}
