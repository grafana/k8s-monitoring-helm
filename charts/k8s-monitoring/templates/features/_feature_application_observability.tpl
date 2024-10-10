{{- define "features.applicationObservability.enabled" }}{{ .Values.applicationObservability.enabled }}{{- end }}

{{- define "features.applicationObservability.collectors" }}
{{- if .Values.applicationObservability.enabled -}}
- {{ .Values.applicationObservability.collector }}
{{- end }}
{{- end }}

{{- define "features.applicationObservability.include" }}
{{- if .Values.applicationObservability.enabled -}}
{{- $destinations := include "features.applicationObservability.destinations" . | fromYamlArray }}

// Feature: Application Observability
{{- include "feature.applicationObservability.module" (dict "Values" $.Values.applicationObservability "Files" $.Subcharts.applicationObservability.Files) }}
application_observability "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "otlp") | indent 4 | trim }}
  ]
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "otlp") | indent 4 | trim }}
  ]
  traces_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "traces" "ecosystem" "otlp") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.applicationObservability.destinations" }}
{{- if .Values.applicationObservability.enabled -}}
{{- $metricsDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- $logDestinations     := include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs"    "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- $traceDestinations   := include "destinations.get" (dict "destinations" $.Values.destinations "type" "traces"  "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- concat $metricsDestinations $logDestinations $traceDestinations | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.applicationObservability.validate" }}
{{- if .Values.applicationObservability.enabled -}}
{{- $featureName := "Application Observability" }}
{{- $metricDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- include "destinations.validate_destination_list" (dict "destinations" $metricDestinations "type" "metrics" "ecosystem" "otlp" "feature" $featureName) }}

{{- $logDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- include "destinations.validate_destination_list" (dict "destinations" $logDestinations "type" "logs" "ecosystem" "loki" "feature" $featureName) }}

{{- $traceDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "traces" "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- include "destinations.validate_destination_list" (dict "destinations" $traceDestinations "type" "traces" "ecosystem" "otlp" "feature" $featureName) }}

{{- include "collectors.require_collector" (dict "Values" $.Values "name" "alloy-receiver" "feature" $featureName) }}
{{- if $.Values.applicationObservability.receivers.grpc.enabled }}
  {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" "alloy-receiver" "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.grpc.port "portName" "otlp-grpc" "portProtocol" "TCP") }}
{{- end -}}
{{- if $.Values.applicationObservability.receivers.http.enabled }}
  {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" "alloy-receiver" "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.http.port "portName" "otlp-http" "portProtocol" "TCP") }}
{{- end -}}
{{- if $.Values.applicationObservability.receivers.zipkin.enabled }}
  {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" "alloy-receiver" "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.zipkin.port "portName" "zipkin" "portProtocol" "TCP") }}
{{- end -}}
{{- include "feature.applicationObservability.validate" (dict "Values" $.Values.applicationObservability) }}
{{- end -}}
{{- end -}}
