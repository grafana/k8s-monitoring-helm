{{- define "features.podLogs.enabled" }}{{ .Values.podLogs.enabled }}{{- end }}
{{- define "features.podLogs.include" }}
{{- if .Values.podLogs.enabled -}}
{{- $destinations := include "features.podLogs.destinations" . | fromYamlArray }}

// Feature: Pod Logs
{{- include "feature.podLogs.module" (dict "Values" $.Values.podLogs "Files" $.Subcharts.podLogs.Files) }}
pod_logs "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.podLogs.destinations" }}
{{- if .Values.podLogs.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.podLogs.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.podLogs.validate" }}
{{- if .Values.podLogs.enabled -}}
{{- $featureName := "Kubernetes Pod logs" }}
{{- $destinations := include "features.podLogs.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "feature" $featureName) }}
{{- include "collectors.require_collector" (dict "Values" $.Values "name" "alloy-logs" "feature" $featureName) }}

{{- include "feature.podLogs.collector.validate" (dict "Values" $.Values.podLogs "Collector" (index .Values "alloy-logs") "CollectorName" "alloy-logs") }}
{{- end -}}
{{- end -}}
