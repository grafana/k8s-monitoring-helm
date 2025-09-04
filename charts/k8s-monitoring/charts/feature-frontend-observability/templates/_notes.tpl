{{- define "feature.applicationObservability.notes.deployments" }}{{- end }}

{{- define "feature.applicationObservability.notes.task" }}
{{- $receivers := list }}
{{- if .Values.receivers.otlp.grpc.enabled }}{{- $receivers = append $receivers "OTLP gRPC" }}{{ end }}
{{- if .Values.receivers.otlp.http.enabled }}{{- $receivers = append $receivers "OTLP HTTP" }}{{ end }}
{{- if .Values.receivers.jaeger.grpc.enabled }}{{- $receivers = append $receivers "Jaeger gRPC" }}{{ end }}
{{- if .Values.receivers.jaeger.thriftBinary.enabled }}{{- $receivers = append $receivers "Jaeger Thrift Binary" }}{{ end }}
{{- if .Values.receivers.jaeger.thriftCompact.enabled }}{{- $receivers = append $receivers "Jaeger Thrift Compact" }}{{ end }}
{{- if .Values.receivers.jaeger.thriftHttp.enabled }}{{- $receivers = append $receivers "Jaeger Thrift HTTP" }}{{ end }}
{{- if .Values.receivers.zipkin.enabled }}{{- $receivers = append $receivers "Zipkin" }}{{ end }}
{{- $receiverWord := len $receivers | plural "receiver" "receivers" }}
Gather application data via {{ include "english_list" $receivers }} {{ $receiverWord }}
{{- end }}

{{- define "feature.applicationObservability.notes.actions" }}
Configure your applications to send telemetry data to:
{{- if .Values.receivers.otlp.grpc.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.otlp.grpc.port }} (OTLP gRPC)
{{- end }}
{{- if .Values.receivers.otlp.http.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.otlp.http.port }} (OTLP HTTP)
{{- end }}
{{- if .Values.receivers.jaeger.grpc.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.jaeger.grpc.port }} (Jaeger gRPC)
{{- end }}
{{- if .Values.receivers.jaeger.thriftBinary.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.jaeger.thriftBinary.port }} (Jaeger Thrift Binary)
{{- end }}
{{- if .Values.receivers.jaeger.thriftCompact.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.jaeger.thriftCompact.port }} (Jaeger Thrift Compact)
{{- end }}
{{- if .Values.receivers.jaeger.thriftHttp.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.jaeger.thriftHttp.port }} (Jaeger Thrift HTTP)
{{- end }}
{{- if .Values.receivers.zipkin.enabled }}
* http://{{ .Collector.ServiceName }}.{{ .Collector.Namespace }}.svc.cluster.local:{{ .Values.receivers.zipkin.port }} (Zipkin)
{{- end }}
{{- end }}

{{- define "feature.applicationObservability.summary" -}}
{{- $receivers := list }}
{{- if .Values.receivers.otlp.grpc.enabled }}{{- $receivers = append $receivers "otlpgrpc" }}{{ end }}
{{- if .Values.receivers.otlp.http.enabled }}{{- $receivers = append $receivers "otlphttp" }}{{ end }}
{{- if .Values.receivers.jaeger.grpc.enabled }}{{- $receivers = append $receivers "jaegergrpc" }}{{ end }}
{{- if .Values.receivers.jaeger.thriftBinary.enabled }}{{- $receivers = append $receivers "jaegerthriftbinary" }}{{ end }}
{{- if .Values.receivers.jaeger.thriftCompact.enabled }}{{- $receivers = append $receivers "jaegerthriftcompact" }}{{ end }}
{{- if .Values.receivers.jaeger.thriftHttp.enabled }}{{- $receivers = append $receivers "jaegerthrifthttp" }}{{ end }}
{{- if .Values.receivers.zipkin.enabled }}{{- $receivers = append $receivers "zipkin" }}{{ end }}
version: {{ .Chart.Version }}
protocols: {{ $receivers | join "," }}
{{- end }}
