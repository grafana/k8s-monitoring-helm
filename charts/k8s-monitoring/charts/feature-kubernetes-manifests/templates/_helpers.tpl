{{- define "escape_label" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}
