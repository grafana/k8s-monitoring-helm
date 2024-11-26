{{- define "features.nodeLogs.enabled" }}{{ .Values.nodeLogs.enabled }}{{- end }}

{{- define "features.nodeLogs.collectors" }}
{{- if .Values.nodeLogs.enabled -}}
- {{ .Values.nodeLogs.collector }}
{{- end }}
{{- end }}

{{- define "features.nodeLogs.include" }}
{{- if .Values.nodeLogs.enabled -}}
{{- $destinations := include "features.nodeLogs.destinations" . | fromYamlArray }}

// Feature: Node Logs
{{- include "feature.nodeLogs.module" (dict "Values" .Values.nodeLogs "Files" $.Subcharts.nodeLogs.Files) }}
node_logs "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.nodeLogs.destinations" }}
{{- if .Values.nodeLogs.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.nodeLogs.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.nodeLogs.validate" }}
{{- if .Values.nodeLogs.enabled -}}
{{- $featureName := "Kubernetes Node logs" }}
{{- $destinations := include "features.nodeLogs.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "feature" $featureName) }}

{{- range $collector := include "features.nodeLogs.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
  {{- include "feature.nodeLogs.collector.validate" (dict "Values" $.Values.nodeLogs "Collector" (index $.Values $collector) "CollectorName" $collector) }}
{{- end -}}
{{- end -}}
{{- end -}}
