{{- define "features.frontendObservability.enabled" }}{{ .Values.frontendObservability.enabled }}{{- end }}
{{- define "features.frontendObservability.include" }}
{{- if .Values.frontendObservability.enabled -}}
{{- $destinations := include "features.frontendObservability.destinations" . | fromYamlArray }}

// Feature: Frontend Observability
{{- include "feature.frontendObservability.module" (dict "Values" $.Values.frontendObservability "Files" $.Subcharts.frontendObservability.Files) }}
frontend_observability "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
  traces_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "traces" "ecosystem" "otlp") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.frontendObservability.destinations" }}
{{- if .Values.frontendObservability.enabled -}}
{{- $logDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.frontendObservability.destinations) | fromYamlArray -}}
{{- $traceDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "traces" "ecosystem" "otlp" "filter" $.Values.frontendObservability.destinations) | fromYamlArray -}}
{{- concat $logDestinations $traceDestinations | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.frontendObservability.validate" }}
{{- if .Values.frontendObservability.enabled -}}
{{- $featureName := "Frontend Observability" }}
{{- $logDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.frontendObservability.destinations) | fromYamlArray -}}
{{- include "destinations.validate_destination_list" (dict "destinations" $logDestinations "type" "logs" "ecosystem" "loki" "feature" $featureName) }}

{{- $traceDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "traces" "ecosystem" "otlp" "filter" $.Values.frontendObservability.destinations) | fromYamlArray -}}
{{- include "destinations.validate_destination_list" (dict "destinations" $traceDestinations "type" "traces" "ecosystem" "otlp" "feature" $featureName) }}

{{- include "collectors.require_collector" (dict "Values" $.Values "name" "alloy-receiver" "feature" $featureName) }}
{{- include "collectors.require_extra_port" (dict "Values" $.Values "name" "alloy-receiver" "feature" $featureName "portNumber" $.Values.frontendObservability.port "portName" "faro" "portProtocol" "TCP") }}
{{- end -}}
{{- end -}}
