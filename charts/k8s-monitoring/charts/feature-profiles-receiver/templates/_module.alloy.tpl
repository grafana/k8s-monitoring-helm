{{- define "feature.profilesReceiver.module" }}
declare "profiles_receiver" {
  argument "profiles_destinations" {
    comment = "Must be a list of profile destinations where collected profiles should be forwarded to"
  }

  pyroscope.receive_http "default" {
    http {
      listen_address = "0.0.0.0"
      listen_port = {{ .Values.port | quote }}
    }
{{ if .Values.profileProcessingRules }}
    forward_to = [pyroscope.relabel.default.receiver]
  } // pyroscope.receive_http "default"

  pyroscope.relabel "default" {
{{ .Values.profileProcessingRules | indent 4 }}
    forward_to = argument.profiles_destinations.value
  } // pyroscope.relabel "default"
{{- else }}
    forward_to = argument.profiles_destinations.value
  } // pyroscope.receive_http "default"
{{- end }}
} // declare "profiles_receiver"
{{- end }}
