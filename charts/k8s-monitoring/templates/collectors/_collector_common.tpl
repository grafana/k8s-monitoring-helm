{{/* Define the logging component.*/}}
{{/* Inputs: . (collector values) */}}
{{- define "collectors.logging.alloy" }}
{{- if or (ne .logging.level "info" ) (ne .logging.format "logfmt") }}
logging {
level  = "{{ .logging.level }}"
format = "{{ .logging.format }}"
}
{{- end }}
{{- end }}

{{/* Define the livedebugging component.*/}}
{{/* Inputs: . (collector values) */}}
{{- define "collectors.liveDebugging.alloy" }}
{{- if .liveDebugging.enabled }}
livedebugging {
enabled = {{ .liveDebugging.enabled }}
}
{{- end }}
{{- end }}
