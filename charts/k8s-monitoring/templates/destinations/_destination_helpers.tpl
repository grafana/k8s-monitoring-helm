{{/* Inputs: destinations (map of destinations), type (string), ecosystem (string), filter (list of destination names) */}}
{{/* Outputs: array of destination names that match the type, ecosystem, and filter */}}
{{- define "destinations.get" }}
{{- $destinations := list }}
{{- $backupDestinations := list }}
{{- range $destinationName, $destination := .destinations }}
  {{- /* Does this destination support the telemetry data type? */}}
  {{- if eq (include (printf "destinations.%s.supports_%s" $destination.type $.type) $destination) "true" }}
    {{- if empty $.filter }}
      {{- /* Is this destination in the ecosystem? */}}
      {{- if eq $.ecosystem (include (printf "destinations.%s.ecosystem" $destination.type) .) }}
        {{- $destinations = append $destinations $destinationName }}
      {{- else }}
        {{- $backupDestinations = append $backupDestinations $destinationName }}
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
  {{- $destination := get .Values.destinations .destination }}
  {{- include (printf "destinations.%s.ecosystem" $destination.type) $destination }}
{{- else }}unknown{{ end }}
{{- end }}
