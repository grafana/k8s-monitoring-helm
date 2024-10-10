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
{{- include (printf "destinations.%s.alloy" $destination.type) (dict "destination" $destination "clusterName" $.Values.cluster.name "Files" $.Files) | indent 0 }}

{{- if eq (include "destinations.secret.uses_k8s_secret" $destination) "true" }}
  {{- include "destinations.secret.alloy" (dict "destination" $destination "Release" $.Release "Chart" $.Chart) | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
