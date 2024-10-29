{{/* Returns an alloy-formatted array of destination targets given the name */}}
{{/* Inputs: destinations (array of destination definition), names ([]string), type (string) ecosystem (string) */}}
{{- define "destinations.alloy.targets" -}}
{{- range $destination := .destinations }}
  {{- if (has $destination.name $.names ) }}
    {{- if eq (include (printf "destinations.%s.supports_%s" $destination.type $.type) $destination) "true" }}
{{ include (printf "destinations.%s.alloy.%s.%s.target" $destination.type $.ecosystem $.type) $destination | trim }},
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Adds the Alloy components for destinations */}}
{{/*Inputs: destinations (array of destination definition), names([]string) clusterName (string), Release (Release object) Chart (Chart object) Files (Files object) */}}
{{- define "destinations.alloy.config" }}
{{- range $destination := .Values.destinations }}
  {{- if (has $destination.name $.names ) }}
// Destination: {{ $destination.name }} ({{ $destination.type }})
{{- include (printf "destinations.%s.alloy" $destination.type) (deepCopy $ | merge (dict "destination" $destination)) | indent 0 }}

{{- if eq (include "secrets.usesKubernetesSecret" $destination) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" $destination)) | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
