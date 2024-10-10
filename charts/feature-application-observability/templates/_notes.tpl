{{- define "feature.applicationObservability.notes.deployments" }}{{- end }}

{{- define "feature.applicationObservability.notes.task" }}
{{- $receivers := list }}
{{- if .Values.receivers.grpc.enabled }}{{- $receivers = append $receivers "OTLP gRPC" }}{{ end }}
{{- if .Values.receivers.http.enabled }}{{- $receivers = append $receivers "OTLP HTTP" }}{{ end }}
{{- if .Values.receivers.zipkin.enabled }}{{- $receivers = append $receivers "Zipkin" }}{{ end }}
{{- $receiverWord := len $receivers | plural "receiver" "receivers" }}
Gather application data via {{ include "english_list" $receivers }} {{ $receiverWord }}
{{- end }}

{{- define "feature.applicationObservability.notes.actions" }}
Configure your applications to send telemetry data to:
{{- if .Values.receivers.grpc.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.grpc.port }} (OTLP gRPC)
{{ end }}
{{- if .Values.receivers.http.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.http.port }} (OTLP HTTP)
{{ end }}
{{- if .Values.receivers.zipkin.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.zipkin.port }} (Zipkin)
{{ end }}
{{- end }}

{{- define "feature.applicationObservability.summary" -}}
{{- $receivers := list }}
{{- if .Values.receivers.grpc.enabled }}{{- $receivers = append $receivers "otlpgrpc" }}{{ end }}
{{- if .Values.receivers.http.enabled }}{{- $receivers = append $receivers "otlphttp" }}{{ end }}
{{- if .Values.receivers.zipkin.enabled }}{{- $receivers = append $receivers "zipkin" }}{{ end }}
version: {{ .Chart.Version }}
protocols: {{ $receivers | join "," }}
{{- end }}
