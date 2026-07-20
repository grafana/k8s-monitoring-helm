{{/* The `router` destination type. A router is a virtual destination: it never talks to a real
     backend. It inspects an attribute (OTLP resource attribute) or the mapped label
     (Prometheus/Loki/Pyroscope) on each record, stamps a `selected_destinations` marker via a
     first-match-wins route table, and fans the record out to one or more real downstream
     destinations. Fan-out reuses the chart's existing per-destination gate helpers
     (pipeline.alloy.gate.ref / pipeline.alloy.gate.render, see
     templates/dataProcessors/_config.alloy.tpl), so a router composes with the normal
     destination machinery rather than duplicating it.

     A router renders in the caller's pipeline ecosystem automatically: the per-tuple
     `.target` helpers below are invoked by destinations.alloy.targets with the feature's
     (ecosystem, signal), so scraped metrics route on the label path and OTLP-collected data
     routes on the OTTL path, independent of where the data is ultimately sent.

     Input is validated by destinations.router.validate (see _destination_validations.tpl)
     before this body renders: defaultDestinations is present and non-empty, every referenced
     downstream exists and is not itself a router, match blocks are well-formed. This body
     therefore assumes valid input. */}}

{{/* Filters an "allDownstream" list down to the destinations that actually support a given signal. */}}
{{/* Inputs: allDownstream ([]string), downstreamInfo (map of name -> {type, values}), signal (string) */}}
{{- define "destinations.router.downstreamForSignal" }}
{{- $result := list }}
{{- $signal := .signal }}
{{- $downstreamInfo := .downstreamInfo }}
{{- range $d := .allDownstream }}
  {{- $info := get $downstreamInfo $d }}
  {{- if eq (include (printf "destinations.%s.supports_%s" $info.type $signal) $info.values) "true" }}
    {{- $result = append $result $d }}
  {{- end }}
{{- end }}
{{- $result | toYaml }}
{{- end }}

{{/* Inputs: . (root object), destination (map), destinationName (name of this destination) */}}
{{- define "destinations.router.alloy" }}
{{- with .destination }}
{{- $routerName := $.destinationName }}
{{- $alloyName := include "helper.alloy_name" $routerName }}
{{- $attribute := .attribute }}
{{- $routes := .routes | default list }}
{{- $defaultDestinations := .defaultDestinations | default list }}

{{- /* Label name used for label-based ecosystems (prometheus/loki/pyroscope). Empty means "no
       label equivalent for this attribute" -> those ecosystems fall back to defaults only.
       Only promoted when the attribute is also a syntactically valid Prometheus label name
       (destinations.router.validate already rejects anything that isn't a valid OTTL attribute
       name, but that's a looser grammar than label names allow -- e.g. `foo-bar` or `foo/bar`
       are valid attribute names but not valid `source_labels` entries). */}}
{{- $labelName := "" }}
{{- if eq $attribute "k8s.namespace.name" }}
  {{- $labelName = "namespace" }}
{{- else if regexMatch "^[a-zA-Z_][a-zA-Z0-9_]*$" $attribute }}
  {{- $labelName = $attribute }}
{{- end }}

{{- /* Union of every destination this router can ever send to: routes[].destinations + defaultDestinations. */}}
{{- $allDownstream := list }}
{{- range $d := $defaultDestinations }}
  {{- if not (has $d $allDownstream) }}{{- $allDownstream = append $allDownstream $d }}{{- end }}
{{- end }}
{{- range $route := $routes }}
  {{- range $d := ($route.destinations | default list) }}
    {{- if not (has $d $allDownstream) }}{{- $allDownstream = append $allDownstream $d }}{{- end }}
  {{- end }}
{{- end }}

{{- /* Resolve each downstream's type + fully-merged-with-defaults values once.
       destinations.router.validate has already asserted every downstream exists. */}}
{{- $downstreamInfo := dict }}
{{- range $d := $allDownstream }}
  {{- $dest := get $.Values.destinations $d }}
  {{- $defaults := (printf "destinations/%s-values.yaml" $dest.type) | $.Files.Get | fromYaml }}
  {{- $merged := mergeOverwrite $defaults $dest }}
  {{- $_ := set $downstreamInfo $d (dict "type" $dest.type "values" $merged) }}
{{- end }}

{{- /* ---------------- metrics/prometheus ---------------- */}}
{{- $metricsDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "metrics") | fromYamlArray }}
// ROUTER: prometheus-ecosystem metrics arrive here, get labeled with "selected_destinations"
// based on {{ $attribute }}{{ if $labelName }} (label "{{ $labelName }}"){{ else }} (no label equivalent - defaults only){{ end }}, and fan out to one gate per downstream destination.
prometheus.relabel {{ printf "%s_metrics_prometheus" $alloyName | quote }} {
{{ include "destinations.router.labelRules" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "metrics" "labelName" $labelName "downstreamInfo" $downstreamInfo) | indent 2 }}
  forward_to = [{{ range $d := $metricsDownstream }}{{ include "pipeline.alloy.gate.ref" (dict "processor" $routerName "destination" $d "type" "metrics" "ecosystem" "prometheus") }}, {{ end }}]
} // prometheus.relabel "{{ $alloyName }}_metrics_prometheus"
{{- range $d := $metricsDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "pipeline.alloy.gate.render" (dict "processor" $routerName "destination" $d "type" "metrics" "ecosystem" "prometheus" "destinationTarget" (include (printf "destinations.%s.alloy.prometheus.metrics.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- /* ---------------- metrics/otlp ---------------- */}}
// ROUTER: OTLP-ecosystem metrics arrive here, get an OTTL-set "selected_destinations" resource
// attribute based on {{ $attribute }}, and fan out to one gate per downstream destination.
otelcol.processor.transform {{ printf "%s_metrics_otlp" $alloyName | quote }} {
  error_mode = "ignore"
  metric_statements {
    context = "resource"
    statements = [
{{ include "destinations.router.ottlStatements" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "metrics" "attribute" $attribute "downstreamInfo" $downstreamInfo) | indent 6 }}
    ]
  }
  output {
    metrics = [{{ range $d := $metricsDownstream }}{{ include "pipeline.alloy.gate.ref" (dict "processor" $routerName "destination" $d "type" "metrics" "ecosystem" "otlp") }}, {{ end }}]
  }
} // otelcol.processor.transform "{{ $alloyName }}_metrics_otlp"
{{- range $d := $metricsDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "pipeline.alloy.gate.render" (dict "processor" $routerName "destination" $d "type" "metrics" "ecosystem" "otlp" "destinationTarget" (include (printf "destinations.%s.alloy.otlp.metrics.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- /* ---------------- logs/loki ---------------- */}}
{{- $logsDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "logs") | fromYamlArray }}
// ROUTER: Loki-ecosystem logs arrive here, get labeled with "selected_destinations"
// based on {{ $attribute }}{{ if $labelName }} (label "{{ $labelName }}"){{ else }} (no label equivalent - defaults only){{ end }}, and fan out to one gate per downstream destination.
loki.relabel {{ printf "%s_logs_loki" $alloyName | quote }} {
{{ include "destinations.router.labelRules" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "logs" "labelName" $labelName "downstreamInfo" $downstreamInfo) | indent 2 }}
  forward_to = [{{ range $d := $logsDownstream }}{{ include "pipeline.alloy.gate.ref" (dict "processor" $routerName "destination" $d "type" "logs" "ecosystem" "loki") }}, {{ end }}]
} // loki.relabel "{{ $alloyName }}_logs_loki"
{{- range $d := $logsDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "pipeline.alloy.gate.render" (dict "processor" $routerName "destination" $d "type" "logs" "ecosystem" "loki" "destinationTarget" (include (printf "destinations.%s.alloy.loki.logs.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- /* ---------------- logs/otlp ---------------- */}}
// ROUTER: OTLP-ecosystem logs arrive here, get an OTTL-set "selected_destinations" resource
// attribute based on {{ $attribute }}, and fan out to one gate per downstream destination.
otelcol.processor.transform {{ printf "%s_logs_otlp" $alloyName | quote }} {
  error_mode = "ignore"
  log_statements {
    context = "resource"
    statements = [
{{ include "destinations.router.ottlStatements" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "logs" "attribute" $attribute "downstreamInfo" $downstreamInfo) | indent 6 }}
    ]
  }
  output {
    logs = [{{ range $d := $logsDownstream }}{{ include "pipeline.alloy.gate.ref" (dict "processor" $routerName "destination" $d "type" "logs" "ecosystem" "otlp") }}, {{ end }}]
  }
} // otelcol.processor.transform "{{ $alloyName }}_logs_otlp"
{{- range $d := $logsDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "pipeline.alloy.gate.render" (dict "processor" $routerName "destination" $d "type" "logs" "ecosystem" "otlp" "destinationTarget" (include (printf "destinations.%s.alloy.otlp.logs.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- /* ---------------- traces/otlp ---------------- */}}
{{- $tracesDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "traces") | fromYamlArray }}
// ROUTER: OTLP traces arrive here, get an OTTL-set "selected_destinations" resource attribute
// based on {{ $attribute }}, and fan out to one gate per downstream destination.
otelcol.processor.transform {{ printf "%s_traces_otlp" $alloyName | quote }} {
  error_mode = "ignore"
  trace_statements {
    context = "resource"
    statements = [
{{ include "destinations.router.ottlStatements" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "traces" "attribute" $attribute "downstreamInfo" $downstreamInfo) | indent 6 }}
    ]
  }
  output {
    traces = [{{ range $d := $tracesDownstream }}{{ include "pipeline.alloy.gate.ref" (dict "processor" $routerName "destination" $d "type" "traces" "ecosystem" "otlp") }}, {{ end }}]
  }
} // otelcol.processor.transform "{{ $alloyName }}_traces_otlp"
{{- range $d := $tracesDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "pipeline.alloy.gate.render" (dict "processor" $routerName "destination" $d "type" "traces" "ecosystem" "otlp" "destinationTarget" (include (printf "destinations.%s.alloy.otlp.traces.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- /* ---------------- profiles/pyroscope ---------------- */}}
{{- $profilesDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "profiles") | fromYamlArray }}
// ROUTER: Pyroscope-ecosystem profiles arrive here, get labeled with "selected_destinations"
// based on {{ $attribute }}{{ if $labelName }} (label "{{ $labelName }}"){{ else }} (no label equivalent - defaults only){{ end }}, and fan out to one gate per downstream destination.
pyroscope.relabel {{ printf "%s_profiles_pyroscope" $alloyName | quote }} {
{{ include "destinations.router.labelRules" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "profiles" "labelName" $labelName "downstreamInfo" $downstreamInfo) | indent 2 }}
  forward_to = [{{ range $d := $profilesDownstream }}{{ include "pipeline.alloy.gate.ref" (dict "processor" $routerName "destination" $d "type" "profiles" "ecosystem" "pyroscope") }}, {{ end }}]
} // pyroscope.relabel "{{ $alloyName }}_profiles_pyroscope"
{{- range $d := $profilesDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "pipeline.alloy.gate.render" (dict "processor" $routerName "destination" $d "type" "profiles" "ecosystem" "pyroscope" "destinationTarget" (include (printf "destinations.%s.alloy.pyroscope.profiles.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- end }}
{{- end }}

{{/* Inputs: routes ([]route), defaultDestinations ([]string), signal (string), labelName (string, may be empty) */}}
{{/* Output: `rule { ... }` blocks for a prometheus.relabel/loki.relabel/pyroscope.relabel component:
     the default is written unconditionally first, then each route whose signals list (if any)
     includes this signal is written in REVERSE declaration order, so relabel's sequential
     rule evaluation makes the FIRST-declared matching route win (later rules overwrite earlier
     ones, and we emit the first route last). */}}
{{- define "destinations.router.labelRules" }}
rule {
  target_label = "selected_destinations"
  replacement  = {{ join "," .defaultDestinations | quote }}
}
{{- if .labelName }}
{{- $signal := .signal }}
{{- $downstreamInfo := .downstreamInfo }}
{{- $routes := .routes }}
{{- $n := len $routes }}
{{- range $i := until $n }}
  {{- $route := index $routes (sub (sub $n 1) $i) }}
  {{- if or (not $route.signals) (has $signal $route.signals) }}
    {{- /* F5: a route's destinations are the RAW list from values (may include destinations
           that don't carry this signal at all). Filter to the ones that actually support this
           signal before stamping -- an unfiltered stamp would name a destination that has no
           gate rendered for this signal (destinations.router.alloy only renders gates for
           downstreamForSignal-filtered lists), so a matching record's marker would match no
           gate's `keep` filter and vanish instead of falling back to defaultDestinations. If
           NOTHING in the route survives the filter for this signal, skip the rule entirely so
           the unconditional default rule above is left standing for matching records. */}}
    {{- $routeDestinations := $route.destinations | default list }}
    {{- $filteredDestinations := include "destinations.router.downstreamForSignal" (dict "allDownstream" $routeDestinations "downstreamInfo" $downstreamInfo "signal" $signal) | fromYamlArray }}
    {{- if not (empty $filteredDestinations) }}
rule {
  source_labels = ["{{ $.labelName }}"]
  regex         = {{ include "destinations.router.matchRegex" $route.match | quote }}
  target_label  = "selected_destinations"
  replacement   = {{ join "," $filteredDestinations | quote }}
}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Inputs: a `match` block ({equals|in|matches}) */}}
{{/* Output: a fully-anchored regex matching the label VALUE. String values are escaped via
     regexQuoteMeta since they arrive as free-form user input, not regex syntax (except `matches`,
     which is documented as a raw regex). */}}
{{- define "destinations.router.matchRegex" }}
{{- if hasKey . "equals" }}{{ printf "^%s$" (regexQuoteMeta (toString .equals)) }}
{{- else if hasKey . "in" }}
  {{- $parts := list }}
  {{- range $v := .in }}{{ $parts = append $parts (regexQuoteMeta (toString $v)) }}{{ end }}
  {{- printf "^(%s)$" (join "|" $parts) }}
{{- else if hasKey . "matches" }}{{ .matches }}
{{- end }}
{{- end }}

{{/* Inputs: routes ([]route), defaultDestinations ([]string), signal (string), attribute (string) */}}
{{/* Output: comma-separated `set(attributes[...], ...) where ...` OTTL statement lines for an
     otelcol.processor.transform statements list: default unconditional first, then each matching
     route in REVERSE order (same first-route-wins trick as labelRules, since OTTL statements
     execute sequentially and each `set` overwrites the previous value). */}}
{{- define "destinations.router.ottlStatements" }}
{{- /* F4: rendered with Helm `quote` (Go %q), not a backtick raw string, so the OUTER Alloy
       string literal correctly escapes double-quotes, backslashes, and newlines that may appear
       in destination/attribute values (a raw backtick string breaks the moment a value contains
       a literal backtick, and can't be used at all for a value containing a newline). ottlEscape
       still does the INNER OTTL-string-literal escaping; quote handles the outer Alloy layer,
       mirroring the stamper idiom in templates/dataProcessors/_config.alloy.tpl. */}}
{{ printf `set(attributes["selected_destinations"], "%s")` (include "destinations.router.ottlEscape" (join "," .defaultDestinations)) | quote }},
{{- $signal := .signal }}
{{- $attribute := .attribute }}
{{- $downstreamInfo := .downstreamInfo }}
{{- $routes := .routes }}
{{- $n := len $routes }}
{{- range $i := until $n }}
  {{- $route := index $routes (sub (sub $n 1) $i) }}
  {{- if or (not $route.signals) (has $signal $route.signals) }}
    {{- /* F5: see the identical filter in destinations.router.labelRules above. */}}
    {{- $routeDestinations := $route.destinations | default list }}
    {{- $filteredDestinations := include "destinations.router.downstreamForSignal" (dict "allDownstream" $routeDestinations "downstreamInfo" $downstreamInfo "signal" $signal) | fromYamlArray }}
    {{- if not (empty $filteredDestinations) }}
{{ printf `set(attributes["selected_destinations"], "%s") where %s` (include "destinations.router.ottlEscape" (join "," $filteredDestinations)) (include "destinations.router.ottlCondition" (dict "attribute" $attribute "match" $route.match)) | quote }},
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Inputs: a string. Output: the string with backslashes then double-quotes escaped, so it is
     safe to splice into a double-quoted OTTL string literal. Order matters: escaping quotes
     before backslashes would double-escape the backslashes just introduced. */}}
{{- define "destinations.router.ottlEscape" }}
{{- . | replace "\\" "\\\\" | replace "\"" "\\\"" }}
{{- end }}

{{/* Inputs: attribute (string), match ({equals|in|matches}) */}}
{{/* Output: an OTTL boolean condition testing the resource attribute against the match. */}}
{{- define "destinations.router.ottlCondition" }}
{{- if hasKey .match "equals" }}attributes["{{ .attribute }}"] == "{{ include "destinations.router.ottlEscape" (toString .match.equals) }}"
{{- else if hasKey .match "in" }}{{/* F1: OTTL has no `in` operator -- render an OR-chain of `==`
        comparisons instead. Each value goes through ottlEscape exactly like the `equals` branch,
        and the whole chain is parenthesized so it composes safely with the `where` clause it's
        spliced into (and with any surrounding boolean logic). */}}({{ range $i, $v := .match.in }}{{ if $i }} or {{ end }}attributes["{{ $.attribute }}"] == "{{ include "destinations.router.ottlEscape" (toString $v) }}"{{ end }})
{{- else if hasKey .match "matches" }}{{/* F2: `matches` is documented as a raw regex, but it is
        still spliced into a double-quoted OTTL string literal, so backslashes and quotes inside
        it must go through the same INNER-layer escaping as equals/in (e.g. `^team-\d+$` must
        render as `^team-\\d+$` so OTTL's own string-literal parser un-escapes it back to the
        intended `\d`). This is regex-content-preserving: ottlEscape never touches regex
        metacharacters, only the two characters that are unsafe inside a double-quoted OTTL
        string. */}}IsMatch(attributes["{{ .attribute }}"], "{{ include "destinations.router.ottlEscape" .match.matches }}") == true
{{- end }}
{{- end }}

{{- define "secrets.list.router" }}{{ end -}}

{{- define "destinations.router.alloy.prometheus.metrics.target" }}prometheus.relabel.{{ include "helper.alloy_name" .destinationName }}_metrics_prometheus.receiver{{ end -}}
{{- define "destinations.router.alloy.otlp.metrics.target" }}otelcol.processor.transform.{{ include "helper.alloy_name" .destinationName }}_metrics_otlp.input{{ end -}}
{{- define "destinations.router.alloy.loki.logs.target" }}loki.relabel.{{ include "helper.alloy_name" .destinationName }}_logs_loki.receiver{{ end -}}
{{- define "destinations.router.alloy.otlp.logs.target" }}otelcol.processor.transform.{{ include "helper.alloy_name" .destinationName }}_logs_otlp.input{{ end -}}
{{- define "destinations.router.alloy.otlp.traces.target" }}otelcol.processor.transform.{{ include "helper.alloy_name" .destinationName }}_traces_otlp.input{{ end -}}
{{- define "destinations.router.alloy.pyroscope.profiles.target" }}pyroscope.relabel.{{ include "helper.alloy_name" .destinationName }}_profiles_pyroscope.receiver{{ end -}}

{{/* A router accepts every signal. supports_<signal> is called with only the router's own
     values (destinations.get / destinations.alloy.targets pass `$destination`, never the root),
     so it cannot inspect downstream capability here. Per-downstream capability is resolved in the
     body (destinations.router.downstreamForSignal excludes a downstream from a signal it does not
     support), and destinations.router.validate warns when a route ends up with no downstream for
     a signal it covers. */}}
{{- define "destinations.router.supports_metrics" }}true{{ end -}}
{{- define "destinations.router.supports_logs" }}true{{ end -}}
{{- define "destinations.router.supports_traces" }}true{{ end -}}
{{- define "destinations.router.supports_profiles" }}true{{ end -}}

{{/* ecosystem is a single value, but a router is multi-ecosystem. We return "otlp". A
     destination's ecosystem only affects implicit destination selection (destinations.get when a
     feature has no explicit `destinations:` list): a router is a primary candidate only for otlp
     lookups, and a backup elsewhere. In practice this means routers must be opted into
     explicitly with `destinations: [myRouter]` on each feature — which is the intended, explicit
     way to use a router. Documented in the destination routing guide. */}}
{{- define "destinations.router.ecosystem" }}otlp{{ end -}}
