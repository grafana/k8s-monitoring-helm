{{- define "feature.profilesReceiver.module" }}
declare "profiles_receiver" {
  pyroscope.receive_http "default" {
    listen_address = "0.0.0.0"
    listen_port = {{ .Values.port | quote }}
{{ if .Values.profileProcessingRules }}
    forward_to = [pyroscope.relabel.default.receiver]
  }

  pyroscope.relabel "default" {
{{ .Values.profileProcessingRules | indent 4 }}
{{- end }}
    forward_to = argument.profiles_destinations.value
  }
}
{{- end }}
