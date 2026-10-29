{{/* Inputs: . (the map of destinations) */}}
{{/* Outputs: The map of destinations, excluding any that set `disabled: true` */}}
{{- define "destinations.getEnabled" }}
{{- $enabledDestinations := dict }}
{{- range $destinationName, $destination := . }}
  {{- if not $destination.disabled }}
    {{- $_ := set $enabledDestinations $destinationName $destination }}
  {{- end }}
{{- end }}
{{- $enabledDestinations | toYaml }}
{{- end }}

{{/* Inputs: destinations (map of destinations), type (string), ecosystem (string), filter (list of destination names) */}}
{{/* Outputs: array of destination names that match the type, ecosystem, and filter */}}
{{- define "destinations.get" }}
{{- $destinations := list }}
{{- $backupDestinations := list }}
{{- $enabledDestinations := include "destinations.getEnabled" .destinations | fromYaml }}
{{- /* F7: destinations that must never be picked up IMPLICITLY (i.e. when a feature sets no
       explicit `destinations:` filter): a router itself, and every real destination named as
       one of its routes[].destinations/defaultDestinations. A router already fans telemetry out
       to those downstreams on its own, so implicitly also sending the same feature's data
       straight to them (bypassing the router's routing rules entirely) would double-deliver it
       and, for a per-tenant router, leak data to every tenant stack outside the router's rules.
       Routers (and whatever sits behind them) must therefore be opted into explicitly with
       `destinations: [myRouter]` -- which is the documented, intended way to use a router. This
       only affects the empty-filter (implicit) branch below; an explicit filter naming a router
       or one of its downstreams still works exactly as before. */}}
{{- $routerShadowed := dict }}
{{- range $destinationName, $destination := $enabledDestinations }}
  {{- if eq $destination.type "router" }}
    {{- $_ := set $routerShadowed $destinationName true }}
    {{- range $d := ($destination.defaultDestinations | default list) }}
      {{- $_ := set $routerShadowed $d true }}
    {{- end }}
    {{- range $route := ($destination.routes | default list) }}
      {{- range $d := ($route.destinations | default list) }}
        {{- $_ := set $routerShadowed $d true }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- range $destinationName, $destination := $enabledDestinations }}
  {{- /* Does this destination support the telemetry data type? */}}
  {{- if eq (include (printf "destinations.%s.supports_%s" $destination.type $.type) $destination) "true" }}
    {{- if empty $.filter }}
      {{- if not (hasKey $routerShadowed $destinationName) }}
      {{- /* Is this destination in the ecosystem? */}}
      {{- if eq $.ecosystem (include (printf "destinations.%s.ecosystem" $destination.type) $destination) }}
        {{- $destinations = append $destinations $destinationName }}
      {{- else }}
        {{- $backupDestinations = append $backupDestinations $destinationName }}
      {{- end }}
      {{- end }}

    {{- /* Did the data source choose this destination? */}}
    {{- else if has $destinationName $.filter }}
      {{- $destinations = append $destinations $destinationName }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if not (empty $destinations) }}
  {{- $destinations | toYaml | indent 0 }}
{{- end }}
{{- /* Output non-ecosystem matching destinations if no ecosystem destinations are found */}}
{{- if and (empty $destinations) (not (empty $backupDestinations)) }}
  {{- $backupDestinations | toYaml | indent 0 }}
{{- end }}
{{- end }}

{{/* Inputs: . (Values), destination (string, name of destination) */}}
{{- define "destination.getEcosystem" }}
{{- if hasKey .Values.destinations .destination }}
  {{- $destinationValues := get .Values.destinations .destination }}
  {{- include (printf "destinations.%s.ecosystem" $destinationValues.type) $destinationValues }}
{{- else }}unknown{{ end }}
{{- end }}

{{/* Inputs: . (Values), destinationName (string, name of destination) */}}
{{- define "destination.supportsMetrics" }}
{{- if hasKey .Values.destinations .destinationName }}
  {{- $destinationValues := get .Values.destinations .destinationName }}
  {{- include (printf "destinations.%s.supports_metrics" $destinationValues.type) $destinationValues }}
{{- else }}false{{ end }}
{{- end }}

{{/* Inputs: . (root object) */}}
{{/* Outputs: a list of unique destination information label sets and their counts */}}
{{- define "destinations.list.info" }}
{{- $destinationInfo := dict }}
{{- range $destinationName, $destination := (include "destinations.getEnabled" $.Values.destinations | fromYaml) }}
  {{- $defaultValues := (printf "destinations/%s-values.yaml" $destination.type) | $.Files.Get | fromYaml }}
  {{- $destinationWithDefaults := mergeOverwrite $defaultValues $destination }}
  {{- $labels := dict "type" $destination.type }}

  {{- if has $destination.type (list "custom" "router") }}
    {{- $ecosystem := $destinationWithDefaults.ecosystem | default "unknown" }}
    {{- if not (has $ecosystem (list "loki" "otlp" "prometheus" "pyroscope")) }}
      {{- $ecosystem = "unknown" }}
    {{- end }}
    {{- $_ := set $labels "ecosystem" $ecosystem }}
  {{- end }}

  {{- if has $destination.type (list "custom" "nop" "otlp") }}
    {{- $_ := set $labels "metrics" (eq (include (printf "destinations.%s.supports_metrics" $destination.type) $destinationWithDefaults | trim) "true" | toString) }}
    {{- $_ := set $labels "logs" (eq (include (printf "destinations.%s.supports_logs" $destination.type) $destinationWithDefaults | trim) "true" | toString) }}
    {{- $_ := set $labels "traces" (eq (include (printf "destinations.%s.supports_traces" $destination.type) $destinationWithDefaults | trim) "true" | toString) }}
  {{- end }}

  {{- if has $destination.type (list "custom" "nop") }}
    {{- $_ := set $labels "profiles" (eq (include (printf "destinations.%s.supports_profiles" $destination.type) $destinationWithDefaults | trim) "true" | toString) }}
  {{- end }}

  {{- if eq $destination.type "otlp" }}
    {{- $_ := set $labels "service_graph_metrics_enabled" (eq (dig "processors" "serviceGraphMetrics" "enabled" false $destinationWithDefaults) true | toString) }}
    {{- $_ := set $labels "tail_sampling_enabled" (eq (dig "processors" "tailSampling" "enabled" false $destinationWithDefaults) true | toString) }}
  {{- end }}

  {{- if eq $destination.type "prometheus" }}
    {{- $_ := set $labels "rules_enabled" (eq (dig "rules" "enabled" false $destinationWithDefaults) true | toString) }}
  {{- end }}

  {{- $key := $labels | toJson }}
  {{- $info := get $destinationInfo $key | default (dict "labels" $labels "count" 0) }}
  {{- $_ := set $info "count" (add (get $info "count") 1) }}
  {{- $_ := set $destinationInfo $key $info }}
{{- end }}
{{- range $key := keys $destinationInfo | sortAlpha }}
  {{- $info := get $destinationInfo $key }}
- labels: {{ $info.labels | toJson }}
  count: {{ $info.count }}
{{- end }}
{{- end }}
