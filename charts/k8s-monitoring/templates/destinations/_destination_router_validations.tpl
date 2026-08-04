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

  {{- /* Ecosystem is mandatory: it decides how conditions are written (resourceAttribute for
         opentelemetry, label for prometheus) and which signals the router serves. */}}
  {{- $ecosystem := $router.ecosystem | default "" }}
  {{- if not (has $ecosystem (list "opentelemetry" "prometheus")) }}
    {{- $msg := list "" (printf "Destination \"%s\" (type: router) has an invalid or missing ecosystem: %q." $name $ecosystem) }}
    {{- $msg = append $msg "A router must set ecosystem to one of: opentelemetry, prometheus." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "destinations:" }}
    {{- $msg = append $msg (printf "  %s:" $name) }}
    {{- $msg = append $msg "    type: router" }}
    {{- $msg = append $msg "    ecosystem: opentelemetry" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
  {{- $expectedKey := ternary "resourceAttribute" "label" (eq $ecosystem "opentelemetry") }}
  {{- $wrongKey := ternary "label" "resourceAttribute" (eq $ecosystem "opentelemetry") }}
  {{- $allowedSignals := ternary (list "metrics" "logs" "traces") (list "metrics" "logs" "profiles") (eq $ecosystem "opentelemetry") }}

  {{- range $i, $route := $routes }}
    {{- $routeNum := add1 $i }}
    {{- $match := $route.match | default list }}
    {{- if not (kindIs "slice" $match) }}
      {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) whose match is not a list." $name $routeNum) }}
      {{- $msg = append $msg (printf "A route's match must be a list of {%s, op, value} conditions (ANDed together)." $expectedKey) }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "destinations:" }}
      {{- $msg = append $msg (printf "  %s:" $name) }}
      {{- $msg = append $msg "    type: router" }}
      {{- $msg = append $msg (printf "    ecosystem: %s" $ecosystem) }}
      {{- $msg = append $msg "    routes:" }}
      {{- $msg = append $msg "      - match:" }}
      {{- $msg = append $msg (printf "          - %s: k8s.namespace.name" $expectedKey) }}
      {{- $msg = append $msg "            op: equals" }}
      {{- $msg = append $msg "            value: my-value" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
    {{- if empty $match }}
      {{- $msg := list "" (printf "Destination \"%s\" (type: router) has a route (#%d) with an empty match." $name $routeNum) }}
      {{- $msg = append $msg "Every route needs at least one match condition." }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- range $ci, $cond := $match }}
      {{- $condNum := add1 $ci }}

      {{- if not (kindIs "map" $cond) }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router) route #%d condition #%d is not a map." $name $routeNum $condNum) }}
        {{- $msg = append $msg (printf "Each condition must be a map with %s, op, and value." $expectedKey) }}
        {{- fail (join "\n" $msg) }}
      {{- end }}

      {{- /* A condition matches on the key for the router's ecosystem. Its value is spliced unquoted
             into the generated OTTL/relabel, so its grammar is enforced to keep user input from
             breaking out of the surrounding Alloy. */}}
      {{- if hasKey $cond $wrongKey }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router, ecosystem: %s) route #%d condition #%d uses `%s`, but an %s router matches on `%s`." $name $ecosystem $routeNum $condNum $wrongKey $ecosystem $expectedKey) }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
      {{- if not (hasKey $cond $expectedKey) }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router, ecosystem: %s) route #%d condition #%d must set `%s`." $name $ecosystem $routeNum $condNum $expectedKey) }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
      {{- $fieldValue := get $cond $expectedKey }}
      {{- if not (kindIs "string" $fieldValue) }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router) route #%d condition #%d %s must be a string: %v." $name $routeNum $condNum $expectedKey $fieldValue) }}
        {{- $msg = append $msg "Please quote it so it isn't parsed as a YAML number, boolean, or null." }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
      {{- if eq $ecosystem "opentelemetry" }}
        {{- if not (regexMatch "^[a-zA-Z_][a-zA-Z0-9_./-]*$" $fieldValue) }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router) route #%d condition #%d has an invalid resourceAttribute: %q." $name $routeNum $condNum $fieldValue) }}
          {{- $msg = append $msg "It must start with a letter or underscore and contain only letters, digits, underscores, dots, slashes, and hyphens -- no quotes, backticks, backslashes, or whitespace." }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
      {{- else }}
        {{- if not (regexMatch "^[a-zA-Z_][a-zA-Z0-9_]*$" $fieldValue) }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router) route #%d condition #%d has an invalid label: %q." $name $routeNum $condNum $fieldValue) }}
          {{- $msg = append $msg "A label must be a valid Prometheus label name: start with a letter or underscore and contain only letters, digits, and underscores." }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
      {{- end }}

      {{- $op := $cond.op | default "" }}
      {{- if not (has $op (list "equals" "notEquals" "in" "matches" "notMatches")) }}
        {{- $msg := list "" (printf "Destination \"%s\" (type: router) route #%d condition #%d has an invalid or missing op: %q." $name $routeNum $condNum $op) }}
        {{- $msg = append $msg "op must be one of: equals, notEquals, in, matches, notMatches." }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
      {{- /* Relabel (prometheus) has only keep/drop, so it can't express negation, and can't
             AND-combine a regex `matches` with other conditions via a separator. */}}
      {{- if eq $ecosystem "prometheus" }}
        {{- if or (eq $op "notEquals") (eq $op "notMatches") }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router, ecosystem: prometheus) route #%d condition #%d uses op `%s`, which the Prometheus/Loki/Pyroscope pipelines cannot express." $name $routeNum $condNum $op) }}
          {{- $msg = append $msg "Use equals, in, or matches -- or an opentelemetry router for negation." }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
        {{- if and (eq $op "matches") (gt (len $match) 1) }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router, ecosystem: prometheus) route #%d condition #%d uses op `matches` alongside other conditions." $name $routeNum $condNum) }}
          {{- $msg = append $msg "A prometheus route combines its conditions by joining labels with a separator, which a regex `matches` cannot participate in. Use `matches` in a single-condition route, or switch to equals/in." }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
      {{- end }}

      {{- /* A non-string YAML value (unquoted bool/number/null) is almost never what the user meant
             to match against. */}}
      {{- if eq $op "in" }}
        {{- if not (kindIs "slice" $cond.value) }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router) route #%d condition #%d uses op `in`, so value must be a list: %v." $name $routeNum $condNum $cond.value) }}
          {{- $msg = append $msg "Please set value to a list, e.g. `value: [a, b]`." }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
        {{- if empty $cond.value }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router) route #%d condition #%d uses op `in` with an empty value list." $name $routeNum $condNum) }}
          {{- $msg = append $msg "`in` needs at least one value to match against." }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
        {{- range $v := $cond.value }}
          {{- if not (kindIs "string" $v) }}
            {{- $msg := list "" (printf "Destination \"%s\" (type: router) route #%d condition #%d has a non-string value in its `in` list: %v." $name $routeNum $condNum $v) }}
            {{- $msg = append $msg "Please quote it so it isn't parsed as a YAML number, boolean, or null." }}
            {{- fail (join "\n" $msg) }}
          {{- end }}
        {{- end }}
      {{- else }}
        {{- if not (kindIs "string" $cond.value) }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router) route #%d condition #%d op `%s` requires a string value: %v." $name $routeNum $condNum $op $cond.value) }}
          {{- $msg = append $msg "Please quote it so it isn't parsed as a YAML number, boolean, or null." }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
        {{- /* The value is used as a regex below, so a compile failure here is exactly the error the
               user needs. */}}
        {{- if or (eq $op "matches") (eq $op "notMatches") }}
          {{- $_ := mustRegexMatch $cond.value "" }}
        {{- end }}
      {{- end }}
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
      {{- $msg = append $msg (printf "          - %s: k8s.namespace.name" $expectedKey) }}
      {{- $msg = append $msg "            op: equals" }}
      {{- $msg = append $msg "            value: my-value" }}
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
        {{- if not (has $s $allowedSignals) }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router, ecosystem: %s) has a route (#%d) covering the \"%s\" signal, which this ecosystem does not route." $name $ecosystem $routeNum $s) }}
          {{- $msg = append $msg (printf "An %s router routes: %s." $ecosystem (join ", " $allowedSignals)) }}
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

  {{- /* R11: every destination the router fans out to must support at least one signal this ecosystem
         routes; otherwise it can never receive anything from this router (e.g. a profiles-only
         Pyroscope destination under an opentelemetry router). supports_<signal> can depend on a
         destination's own config (e.g. otlp reads logs.enabled), so resolve merged values the same
         way the router body does. */}}
  {{- $referenced := list }}
  {{- range $route := $routes }}
    {{- range $d := ($route.destinations | default list) }}
      {{- if not (has $d $referenced) }}{{- $referenced = append $referenced $d }}{{- end }}
    {{- end }}
  {{- end }}
  {{- range $d := $defaultDestinations }}
    {{- if not (has $d $referenced) }}{{- $referenced = append $referenced $d }}{{- end }}
  {{- end }}
  {{- range $d := $referenced }}
    {{- if hasKey $enabledDestinations $d }}
      {{- $dest := get $enabledDestinations $d }}
      {{- if ne $dest.type "router" }}
        {{- $defaults := (printf "destinations/%s-values.yaml" $dest.type) | $root.Files.Get | fromYaml }}
        {{- $merged := mergeOverwrite $defaults $dest }}
        {{- $supportsAny := false }}
        {{- range $s := $allowedSignals }}
          {{- if eq (include (printf "destinations.%s.supports_%s" $dest.type $s) $merged) "true" }}{{- $supportsAny = true }}{{- end }}
        {{- end }}
        {{- if not $supportsAny }}
          {{- $msg := list "" (printf "Destination \"%s\" (type: router, ecosystem: %s) fans out to destination \"%s\" (type: %s), which cannot receive any signal an %s router routes (%s)." $name $ecosystem $d $dest.type $ecosystem (join ", " $allowedSignals)) }}
          {{- $msg = append $msg (printf "Point this router only at destinations that support %s, or change the router's ecosystem." (join "/" $allowedSignals)) }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
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
  {{- $ecosystem := .ecosystem }}
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

  {{- /* Ecosystem compatibility: the feature's collection pipeline must match the router's declared
         ecosystem (opentelemetry <-> otlp; prometheus <-> prometheus/loki/pyroscope). This seam is the
         only place the feature's real collection ecosystem is known. */}}
  {{- $routerEcosystem := $router.ecosystem | default "" }}
  {{- $compatible := ternary (eq $ecosystem "otlp") (has $ecosystem (list "prometheus" "loki" "pyroscope")) (eq $routerEcosystem "opentelemetry") }}
  {{- if not $compatible }}
    {{- $msg := list "" (printf "Feature \"%s\" collects %s via the %s pipeline and routes it through router \"%s\", but that router is declared ecosystem: %s." $featureKey $type $ecosystem $routerName $routerEcosystem) }}
    {{- $msg = append $msg (printf "An %s router can only route %s-collected data." $routerEcosystem (ternary "OpenTelemetry Protocol" "Prometheus/Loki/Pyroscope" (eq $routerEcosystem "opentelemetry"))) }}
    {{- $msg = append $msg "Point this feature at a router whose ecosystem matches the feature's collection pipeline." }}
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
  {{- $routes := $router.routes | default list }}
  {{- $defaultDestinations := $router.defaultDestinations | default list }}
  {{- $ecosystem := $router.ecosystem | default "" }}
  {{- $ecosystemSignals := ternary (list "metrics" "logs" "traces") (list "metrics" "logs" "profiles") (eq $ecosystem "opentelemetry") }}

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
    {{- $signals := $route.signals | default $ecosystemSignals }}
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
