{{- define "features.podLogs.enabled" }}{{ .Values.podLogs.enabled }}{{- end }}

{{- define "features.podLogs.collectors" }}
{{- if .Values.podLogs.enabled -}}
- {{ .Values.podLogs.collector }}
{{- end }}
{{- end }}

{{- define "features.podLogs.include" }}
{{- if .Values.podLogs.enabled -}}
{{- $extraDiscoveryRules := cat (include "features.integrations.logs.discoveryRules" .) "\n" .Values.podLogs.extraDiscoveryRules | trim }}
{{- $extraLogProcessingStages := cat (include "features.integrations.logs.logProcessingStages" .) "\n" .Values.podLogs.extraLogProcessingStages | trim }}
{{- $values := mergeOverwrite .Values.podLogs (dict "extraDiscoveryRules" $extraDiscoveryRules "extraLogProcessingStages" $extraLogProcessingStages) }}
{{- $destinations := include "features.podLogs.destinations" . | fromYamlArray }}

// Feature: Pod Logs
{{- include "feature.podLogs.module" (dict "Values" $values "Files" $.Subcharts.podLogs.Files) }}
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

{{- range $collector := include "features.podLogs.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
  {{- include "feature.podLogs.collector.validate" (dict "Values" $.Values.podLogs "Collector" (index $.Values $collector) "CollectorName" $collector) }}
{{- end -}}
{{- end -}}
{{- end -}}
