{{/* Inputs: destinations (array of destination names), type (string), feature (string) */}}
{{- define "destinations.validate_destination_list" -}}
{{- if empty .destinations }}
{{- $msg := list "" (printf "No destinations found that can accept %s from %s" .type .feature) }}
{{- $msg = append $msg (printf "Please add a destination with %s support." .type) }}
{{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/destinations/README.md for more details." }}
{{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Inputs: destinations (array of destination definition), type (string), ecosystem (string), filter (list of destination names) */}}
{{- define "destinations.get" -}}
{{- $destinations := list }}
{{- $backupDestinations := list }}
{{- range $destination := .destinations }}
  {{- /* Does this destination support the telemetry data type? */}}
  {{- if eq (include (printf "destinations.%s.supports_%s" $destination.type $.type) $destination) "true" }}
    {{- if empty $.filter }}
      {{- /* Is this destination in the ecosystem? */}}
      {{- if eq $.ecosystem (include (printf "destinations.%s.ecosystem" $destination.type) .) }}
        {{- $destinations = append $destinations $destination.name }}
      {{- else }}
        {{- $backupDestinations = append $backupDestinations $destination.name }}
      {{- end }}

    {{- /* Did the data source choose this destination? */}}
    {{- else if has $destination.name $.filter }}
      {{- $destinations = append $destinations $destination.name }}
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
