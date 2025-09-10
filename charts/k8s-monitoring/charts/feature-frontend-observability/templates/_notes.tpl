{{- define "feature.frontendObservability.notes.deployments" }}{{- end }}

{{- define "feature.frontendObservability.notes.task" }}
{{- $receivers := list }}
{{- if .Values.receivers.faro.enabled }}{{- $receivers = append $receivers "Faro" }}{{ end }}
{{- $receiverWord := len $receivers | plural "receiver" "receivers" }}
Gather Faro application data via {{ include "english_list" $receivers }} {{ $receiverWord }}
{{- end }}

{{- define "feature.frontendObservability.notes.actions" }}
Configure your frontend applications to send telemetry data to:
{{- if .Values.receivers.faro.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.faro.port }} (Faro)
{{- end }}
{{- end }}

{{- define "feature.frontendObservability.summary" -}}
{{- $receivers := list }}
{{- if .Values.receivers.faro.enabled }}{{- $receivers = append $receivers "faro" }}{{ end }}
version: {{ .Chart.Version }}
protocols: {{ $receivers | join "," }}
{{- end }}
