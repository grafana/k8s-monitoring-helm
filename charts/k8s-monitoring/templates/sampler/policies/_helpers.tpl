{{/*
  Takes a list of strings and returns a new list where each element is quoted
*/}}
{{- define "policy.quoteAll" -}}
{{- $quoted := list -}}
{{- range . }}
  {{- $quoted = append $quoted (printf "%q" .) -}}
{{- end }}
{{- join ", " $quoted -}}
{{- end }}

