{{- define "escape_label" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}

{{- define "helper.namespace" -}}
{{- .Values.global.namespaceOverride | default .Release.Namespace -}}
{{- end -}}
