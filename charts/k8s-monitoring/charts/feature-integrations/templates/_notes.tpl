{{- define "feature.integrations.notes.deployments" }}{{- end }}

{{- define "feature.integrations.notes.task" }}
{{- $sources := list }}
{{- range $integration := (include "integrations.types" . | fromYamlArray) }}
  {{- if (index $.Values $integration).instances -}}
    {{- $sources = append $sources $integration -}}
  {{- end -}}
{{- end }}
{{- if $sources }}
Gather data from the {{ include "english_list" $sources }} {{ if eq (len $sources) 1 }}integration{{ else }}integrations{{ end }}
{{- end }}
{{- end }}

{{- define "feature.integrations.notes.actions" }}{{- end }}

{{- define "feature.integrations.summary" -}}
{{- $sources := list }}
{{- range $integration := (include "integrations.types" . | fromYamlArray) }}
  {{- if (index $.Values $integration).instances -}}
    {{- $sources = append $sources $integration -}}
  {{- end -}}
{{- end }}
version: {{ .Chart.Version }}
sources: {{ $sources | join "," }}
{{- end }}
