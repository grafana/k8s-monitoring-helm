{{/* Define the logging component.*/}}
{{/* Inputs: collectorName (string), Values */}}
{{- define "collectors.logging.alloy" }}
{{- with (index .Values .collectorName).logging }}
  {{- if or (ne .level "info" ) (ne .format "logfmt") }}
logging {
  level  = "{{ .level }}"
  format = "{{ .format }}"
}
  {{- end }}
{{- end }}
{{- end }}

{{/* Define the livedebugging component.*/}}
{{/* Inputs: collectorName (string), Values */}}
{{- define "collectors.liveDebugging.alloy" }}
{{- with (index .Values .collectorName).liveDebugging }}
  {{- if .enabled }}
livedebugging {
  enabled = {{ .enabled }}
}
  {{- end }}
{{- end }}
{{- end }}
