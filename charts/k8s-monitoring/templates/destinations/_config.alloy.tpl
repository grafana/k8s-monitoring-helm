{{/* Returns an alloy-formatted array of destination targets given the name */}}
{{/* Inputs: destinations (map of destinations), destinationNames ([]string), type (string) ecosystem (string) */}}
{{- define "destinations.alloy.targets" -}}
{{- range $destinationName := .destinationNames }}
  {{- if hasKey $.destinations $destinationName }}
    {{- $destination := get $.destinations $destinationName }}
      {{- if eq (include (printf "destinations.%s.supports_%s" $destination.type $.type) $destination) "true" }}
{{ include (printf "destinations.%s.alloy.%s.%s.target" $destination.type $.ecosystem $.type) (dict "destination" $destination "destinationName" $destinationName) | trim }},
      {{- end }}
    {{- end }}
  {{- else }}
    {{ $msg := list "" (printf "A destination named \"%s\" was referenced but not defined.")}}
  {{- end }}
{{- end }}

{{/* Adds the Alloy components for destinations */}}
{{/* Inputs: . (root object) destinationNames (list of destination names) */}}
{{- define "destinations.alloy.config" }}
{{- range $destinationName := .destinationNames }}
  {{- if hasKey $.Values.destinations $destinationName }}
    {{- $destination := get $.Values.destinations $destinationName }}
    {{- $defaultValues := (printf "destinations/%s-values.yaml" $destination.type) | $.Files.Get | fromYaml }}
    {{- $destinationWithDefaults := mergeOverwrite $defaultValues $destination }}
// Destination: {{ $destinationName }} ({{ $destination.type }})
{{- include (printf "destinations.%s.alloy" $destination.type) (deepCopy $ | merge (dict "destination" $destinationWithDefaults "destinationName" $destinationName)) | indent 0 }}

    {{- if eq (include "secrets.usesKubernetesSecret" $destinationWithDefaults) "true" }}
      {{- include "secret.alloy" (deepCopy $ | merge (dict "object" $destinationWithDefaults "name" $destinationName)) | nindent 0 }}
    {{- end }}
  {{ else }}
    {{ $msg := list "" (printf "A destination named \"%s\" was referenced but not defined.")}}
  {{- end }}
{{- end }}
{{- end }}

{{/* Renders mimir.rules.kubernetes blocks for any prometheus destination with rules.enabled.
     Each block is gated to the destination's chosen collector, so exactly one Alloy instance
     owns rule synchronization with the Mimir Ruler API. */}}
{{/* Inputs: . (root object), collectorName (string) */}}
{{- define "destinations.alloy.rules" }}
{{- range $destinationName, $destination := $.Values.destinations }}
  {{- if eq $destination.type "prometheus" }}
    {{- $defaultValues := (printf "destinations/%s-values.yaml" $destination.type) | $.Files.Get | fromYaml }}
    {{- $destinationWithDefaults := mergeOverwrite $defaultValues $destination }}
    {{- if and $destinationWithDefaults.rules $destinationWithDefaults.rules.enabled }}
      {{- include "destinations.prometheus.rules.alloy" (deepCopy $ | merge (dict "destination" $destinationWithDefaults "destinationName" $destinationName "collectorName" $.collectorName)) | nindent 0 }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
