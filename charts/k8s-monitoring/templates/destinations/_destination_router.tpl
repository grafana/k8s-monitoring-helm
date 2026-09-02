{{/* The `router` destination type: a virtual destination (never a real backend) that stamps a
     `selected_destinations` marker and fans records out to real destinations through the shared gate
     helpers, so it composes with the normal destination machinery instead of duplicating it. Its
     `ecosystem` names the collection pipeline it routes: `otlp` matches resourceAttributes with OTTL
     (metrics/logs/traces); `prometheus`/`loki`/`pyroscope` match labels with relabel (metrics, logs,
     profiles respectively). Assumes valid input -- destinations.router.validate runs first. */}}

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

{{- define "destinations.router.field.ottlAccessor" -}}
attributes["{{ .resourceAttribute }}"]
{{- end -}}

{{/* One template per operator, dispatched by op.render (the switch at the end). Each operator
     renders itself for the target named by `.render`: `ottl` (an OTTL boolean expression),
     `relabelAnchored` (a fully-anchored regex for a single-condition relabel rule), or
     `relabelFragment` (an unanchored regex fragment that AND-combines with others in one
     multi-condition relabel rule). An operator omits the targets it can't express, so what an
     operator supports is visible in its own template and the full operator set is visible in
     op.render. Inputs: render (string), value (string or []string), accessor (string, ottl only). */}}

{{- define "destinations.router.op.equals" -}}
{{- if eq .render "ottl" -}}{{ .accessor }} == "{{ include "destinations.router.ottlEscape" (toString .value) }}"
{{- else if eq .render "relabelAnchored" -}}{{ printf "^%s$" (regexQuoteMeta (toString .value)) }}
{{- else if eq .render "relabelFragment" -}}{{ regexQuoteMeta (toString .value) }}
{{- end -}}
{{- end -}}

{{/* Negation, so OTLP-only: relabel can only keep, not exclude. */}}
{{- define "destinations.router.op.notEquals" -}}
{{- if eq .render "ottl" -}}{{ .accessor }} != "{{ include "destinations.router.ottlEscape" (toString .value) }}"
{{- end -}}
{{- end -}}

{{/* OTTL has no `in`, so it becomes a parenthesized OR-chain of `==`. */}}
{{- define "destinations.router.op.in" -}}
{{- $acc := .accessor -}}
{{- if eq .render "ottl" -}}({{ range $i, $v := .value }}{{ if $i }} or {{ end }}{{ $acc }} == "{{ include "destinations.router.ottlEscape" (toString $v) }}"{{ end }})
{{- else if eq .render "relabelAnchored" -}}
{{- $parts := list -}}
{{- range $v := .value -}}{{ $parts = append $parts (regexQuoteMeta (toString $v)) }}{{- end -}}
{{- printf "^(%s)$" (join "|" $parts) -}}
{{- else if eq .render "relabelFragment" -}}
{{- $parts := list -}}
{{- range $v := .value -}}{{ $parts = append $parts (regexQuoteMeta (toString $v)) }}{{- end -}}
{{- printf "(%s)" (join "|" $parts) -}}
{{- end -}}
{{- end -}}

{{/* Raw regex. No fragment form: a raw regex can't AND-combine via a separator, so on relabel it is
     single-condition only (validation enforces this). */}}
{{- define "destinations.router.op.matches" -}}
{{- if eq .render "ottl" -}}IsMatch({{ .accessor }}, "{{ include "destinations.router.ottlEscape" (toString .value) }}") == true
{{- else if eq .render "relabelAnchored" -}}{{ toString .value }}
{{- end -}}
{{- end -}}

{{/* Negation, so OTLP-only. */}}
{{- define "destinations.router.op.notMatches" -}}
{{- if eq .render "ottl" -}}not IsMatch({{ .accessor }}, "{{ include "destinations.router.ottlEscape" (toString .value) }}")
{{- end -}}
{{- end -}}

{{/* The switch: the operators the router supports are exactly the cases listed here. */}}
{{- define "destinations.router.op.render" -}}
{{- $op := .op -}}
{{- if eq $op "equals" -}}{{ include "destinations.router.op.equals" . }}
{{- else if eq $op "notEquals" -}}{{ include "destinations.router.op.notEquals" . }}
{{- else if eq $op "in" -}}{{ include "destinations.router.op.in" . }}
{{- else if eq $op "matches" -}}{{ include "destinations.router.op.matches" . }}
{{- else if eq $op "notMatches" -}}{{ include "destinations.router.op.notMatches" . }}
{{- end -}}
{{- end -}}

{{/* Inputs: . (root object), destination (map), destinationName (name of this destination) */}}
{{- define "destinations.router.alloy" }}
{{- with .destination }}
{{- $routerName := $.destinationName }}
{{- $alloyName := include "helper.alloy_name" $routerName }}
{{- $ecosystem := .ecosystem }}
{{- $routes := .routes | default list }}
{{- $defaultDestinations := .defaultDestinations | default list }}

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

{{- if eq $ecosystem "otlp" }}
{{- /* ---------------- metrics/otlp ---------------- */}}
{{- $metricsDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "metrics") | fromYamlArray }}
// ROUTER: OTLP-ecosystem metrics arrive here, get an OTTL-set "selected_destinations" resource
// attribute based on the route match conditions, and fan out to one gate per downstream destination.
otelcol.processor.transform {{ printf "%s_metrics_otlp" $alloyName | quote }} {
  error_mode = "ignore"
  metric_statements {
    context = "resource"
    statements = [
{{ include "destinations.router.ottlStatements" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "metrics" "downstreamInfo" $downstreamInfo) | indent 6 }}
    ]
  }
  output {
    metrics = [{{ range $d := $metricsDownstream }}{{ include "dataProcessors.pipeline.gate.ref" (dict "processor" $routerName "destination" $d "type" "metrics" "ecosystem" "otlp") }}, {{ end }}]
  }
} // otelcol.processor.transform "{{ $alloyName }}_metrics_otlp"
{{- range $d := $metricsDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "dataProcessors.pipeline.gate.render" (dict "processor" $routerName "destination" $d "type" "metrics" "ecosystem" "otlp" "destinationTarget" (include (printf "destinations.%s.alloy.otlp.metrics.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- /* ---------------- logs/otlp ---------------- */}}
{{- $logsDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "logs") | fromYamlArray }}
// ROUTER: OTLP-ecosystem logs arrive here, get an OTTL-set "selected_destinations" resource
// attribute based on the route match conditions, and fan out to one gate per downstream destination.
otelcol.processor.transform {{ printf "%s_logs_otlp" $alloyName | quote }} {
  error_mode = "ignore"
  log_statements {
    context = "resource"
    statements = [
{{ include "destinations.router.ottlStatements" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "logs" "downstreamInfo" $downstreamInfo) | indent 6 }}
    ]
  }
  output {
    logs = [{{ range $d := $logsDownstream }}{{ include "dataProcessors.pipeline.gate.ref" (dict "processor" $routerName "destination" $d "type" "logs" "ecosystem" "otlp") }}, {{ end }}]
  }
} // otelcol.processor.transform "{{ $alloyName }}_logs_otlp"
{{- range $d := $logsDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "dataProcessors.pipeline.gate.render" (dict "processor" $routerName "destination" $d "type" "logs" "ecosystem" "otlp" "destinationTarget" (include (printf "destinations.%s.alloy.otlp.logs.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- /* ---------------- traces/otlp ---------------- */}}
{{- $tracesDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "traces") | fromYamlArray }}
// ROUTER: OTLP traces arrive here, get an OTTL-set "selected_destinations" resource attribute
// based on the route match conditions, and fan out to one gate per downstream destination.
otelcol.processor.transform {{ printf "%s_traces_otlp" $alloyName | quote }} {
  error_mode = "ignore"
  trace_statements {
    context = "resource"
    statements = [
{{ include "destinations.router.ottlStatements" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "traces" "downstreamInfo" $downstreamInfo) | indent 6 }}
    ]
  }
  output {
    traces = [{{ range $d := $tracesDownstream }}{{ include "dataProcessors.pipeline.gate.ref" (dict "processor" $routerName "destination" $d "type" "traces" "ecosystem" "otlp") }}, {{ end }}]
  }
} // otelcol.processor.transform "{{ $alloyName }}_traces_otlp"
{{- range $d := $tracesDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "dataProcessors.pipeline.gate.render" (dict "processor" $routerName "destination" $d "type" "traces" "ecosystem" "otlp" "destinationTarget" (include (printf "destinations.%s.alloy.otlp.traces.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- else if eq $ecosystem "prometheus" }}
{{- /* ---------------- metrics/prometheus ---------------- */}}
{{- $metricsDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "metrics") | fromYamlArray }}
// ROUTER: prometheus-ecosystem metrics arrive here, get labeled with "selected_destinations"
// based on the route match conditions, and fan out to one gate per downstream destination.
prometheus.relabel {{ printf "%s_metrics_prometheus" $alloyName | quote }} {
{{ include "destinations.router.labelRules" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "metrics" "downstreamInfo" $downstreamInfo) | indent 2 }}
  forward_to = [{{ range $d := $metricsDownstream }}{{ include "dataProcessors.pipeline.gate.ref" (dict "processor" $routerName "destination" $d "type" "metrics" "ecosystem" "prometheus") }}, {{ end }}]
} // prometheus.relabel "{{ $alloyName }}_metrics_prometheus"
{{- range $d := $metricsDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "dataProcessors.pipeline.gate.render" (dict "processor" $routerName "destination" $d "type" "metrics" "ecosystem" "prometheus" "destinationTarget" (include (printf "destinations.%s.alloy.prometheus.metrics.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- else if eq $ecosystem "loki" }}
{{- /* ---------------- logs/loki ---------------- */}}
{{- $logsDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "logs") | fromYamlArray }}
// ROUTER: Loki-ecosystem logs arrive here, get labeled with "selected_destinations"
// based on the route match conditions, and fan out to one gate per downstream destination.
loki.relabel {{ printf "%s_logs_loki" $alloyName | quote }} {
{{ include "destinations.router.labelRules" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "logs" "downstreamInfo" $downstreamInfo) | indent 2 }}
  forward_to = [{{ range $d := $logsDownstream }}{{ include "dataProcessors.pipeline.gate.ref" (dict "processor" $routerName "destination" $d "type" "logs" "ecosystem" "loki") }}, {{ end }}]
} // loki.relabel "{{ $alloyName }}_logs_loki"
{{- range $d := $logsDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "dataProcessors.pipeline.gate.render" (dict "processor" $routerName "destination" $d "type" "logs" "ecosystem" "loki" "destinationTarget" (include (printf "destinations.%s.alloy.loki.logs.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- else if eq $ecosystem "pyroscope" }}
{{- /* ---------------- profiles/pyroscope ---------------- */}}
{{- $profilesDownstream := include "destinations.router.downstreamForSignal" (dict "allDownstream" $allDownstream "downstreamInfo" $downstreamInfo "signal" "profiles") | fromYamlArray }}
// ROUTER: Pyroscope-ecosystem profiles arrive here, get labeled with "selected_destinations"
// based on the route match conditions, and fan out to one gate per downstream destination.
pyroscope.relabel {{ printf "%s_profiles_pyroscope" $alloyName | quote }} {
{{ include "destinations.router.labelRules" (dict "routes" $routes "defaultDestinations" $defaultDestinations "signal" "profiles" "downstreamInfo" $downstreamInfo) | indent 2 }}
  forward_to = [{{ range $d := $profilesDownstream }}{{ include "dataProcessors.pipeline.gate.ref" (dict "processor" $routerName "destination" $d "type" "profiles" "ecosystem" "pyroscope") }}, {{ end }}]
} // pyroscope.relabel "{{ $alloyName }}_profiles_pyroscope"
{{- range $d := $profilesDownstream }}
{{- $info := get $downstreamInfo $d }}
{{ include "dataProcessors.pipeline.gate.render" (dict "processor" $routerName "destination" $d "type" "profiles" "ecosystem" "pyroscope" "destinationTarget" (include (printf "destinations.%s.alloy.pyroscope.profiles.target" $info.type) (dict "destination" $info.values "destinationName" $d) | trim)) }}
{{- end }}

{{- end }}
{{- end }}
{{- end }}

{{/* Routes are emitted in REVERSE declaration order so relabel's later-wins evaluation makes the
     first-declared matching route win. */}}
{{- define "destinations.router.labelRules" }}
rule {
  target_label = "selected_destinations"
  replacement  = {{ join "," .defaultDestinations | quote }}
}
{{- $signal := .signal }}
{{- $downstreamInfo := .downstreamInfo }}
{{- $routes := .routes }}
{{- $n := len $routes }}
{{- range $i := until $n }}
{{- $route := index $routes (sub (sub $n 1) $i) }}
{{- if or (not $route.signals) (has $signal $route.signals) }}
{{- $routeDestinations := $route.destinations | default list }}
{{- $filteredDestinations := include "destinations.router.downstreamForSignal" (dict "allDownstream" $routeDestinations "downstreamInfo" $downstreamInfo "signal" $signal) | fromYamlArray }}
{{- if not (empty $filteredDestinations) }}
{{- $match := $route.match | default list }}
{{- $replacement := join "," $filteredDestinations }}
{{- if eq (len $match) 1 }}
{{- $p := index $match 0 }}
rule {
  source_labels = [{{ $p.label | quote }}]
  regex         = {{ include "destinations.router.op.render" (dict "render" "relabelAnchored" "op" $p.op "value" $p.value) | quote }}
  target_label  = "selected_destinations"
  replacement   = {{ $replacement | quote }}
}
{{- else }}
{{- $labels := list }}
{{- $frags := list }}
{{- range $p := $match }}
{{- $labels = append $labels $p.label }}
{{- $frags = append $frags (include "destinations.router.op.render" (dict "render" "relabelFragment" "op" $p.op "value" $p.value)) }}
{{- end }}
rule {
  source_labels = [{{ range $j, $l := $labels }}{{ if $j }}, {{ end }}{{ $l | quote }}{{ end }}]
  separator     = ";"
  regex         = {{ printf "^%s$" (join ";" $frags) | quote }}
  target_label  = "selected_destinations"
  replacement   = {{ $replacement | quote }}
}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Reverse declaration order (same first-wins trick as labelRules): OTTL `set` statements run
     sequentially and each overwrites the previous. A route's conditions are ANDed with ` and `. */}}
{{- define "destinations.router.ottlStatements" }}
{{ printf `set(attributes["selected_destinations"], "%s")` (include "destinations.router.ottlEscape" (join "," .defaultDestinations)) | quote }},
{{- $signal := .signal }}
{{- $downstreamInfo := .downstreamInfo }}
{{- $routes := .routes }}
{{- $n := len $routes }}
{{- range $i := until $n }}
{{- $route := index $routes (sub (sub $n 1) $i) }}
{{- if or (not $route.signals) (has $signal $route.signals) }}
{{- $routeDestinations := $route.destinations | default list }}
{{- $filteredDestinations := include "destinations.router.downstreamForSignal" (dict "allDownstream" $routeDestinations "downstreamInfo" $downstreamInfo "signal" $signal) | fromYamlArray }}
{{- if not (empty $filteredDestinations) }}
{{- $conds := list }}
{{- range $p := ($route.match | default list) }}
{{- $acc := include "destinations.router.field.ottlAccessor" $p }}
{{- $conds = append $conds (include "destinations.router.op.render" (dict "render" "ottl" "accessor" $acc "op" $p.op "value" $p.value)) }}
{{- end }}
{{ printf `set(attributes["selected_destinations"], "%s") where %s` (include "destinations.router.ottlEscape" (join "," $filteredDestinations)) (join " and " $conds) | quote }},
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

{{- define "secrets.list.router" }}{{ end -}}

{{- define "destinations.router.alloy.prometheus.metrics.target" }}prometheus.relabel.{{ include "helper.alloy_name" .destinationName }}_metrics_prometheus.receiver{{ end -}}
{{- define "destinations.router.alloy.otlp.metrics.target" }}otelcol.processor.transform.{{ include "helper.alloy_name" .destinationName }}_metrics_otlp.input{{ end -}}
{{- define "destinations.router.alloy.loki.logs.target" }}loki.relabel.{{ include "helper.alloy_name" .destinationName }}_logs_loki.receiver{{ end -}}
{{- define "destinations.router.alloy.otlp.logs.target" }}otelcol.processor.transform.{{ include "helper.alloy_name" .destinationName }}_logs_otlp.input{{ end -}}
{{- define "destinations.router.alloy.otlp.traces.target" }}otelcol.processor.transform.{{ include "helper.alloy_name" .destinationName }}_traces_otlp.input{{ end -}}
{{- define "destinations.router.alloy.pyroscope.profiles.target" }}pyroscope.relabel.{{ include "helper.alloy_name" .destinationName }}_profiles_pyroscope.receiver{{ end -}}

{{/* An otlp router carries the OTLP signals (metrics/logs/traces); prometheus/loki/pyroscope routers
     each carry their single label-based signal. supports_<signal> receives only the router's own
     values, so it branches on `.ecosystem`. */}}
{{- define "destinations.router.supports_metrics" }}{{ if has (.ecosystem | default "") (list "otlp" "prometheus") }}true{{ end }}{{ end -}}
{{- define "destinations.router.supports_logs" }}{{ if has (.ecosystem | default "") (list "otlp" "loki") }}true{{ end }}{{ end -}}
{{- define "destinations.router.supports_traces" }}{{ if eq (.ecosystem | default "") "otlp" }}true{{ end }}{{ end -}}
{{- define "destinations.router.supports_profiles" }}{{ if eq (.ecosystem | default "") "pyroscope" }}true{{ end }}{{ end -}}

{{/* A router's ecosystem is already one of the chart's collection-ecosystem values, so return it
     directly (used only for implicit destination selection, from which routers are excluded). */}}
{{- define "destinations.router.ecosystem" }}{{ .ecosystem | default "otlp" }}{{ end -}}
