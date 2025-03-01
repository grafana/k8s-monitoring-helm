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
{{- include "feature.podLogs.validate" (dict "Values" $.Values.podLogs "Capabilities" $.Capabilities) }}
{{- $featureName := "Kubernetes Pod logs" }}
{{- $destinations := include "features.podLogs.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "feature" $featureName) }}

{{- range $collector := include "features.podLogs.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
  {{- include "feature.podLogs.collector.validate" (dict "Values" $.Values.podLogs "Collector" (index $.Values $collector) "CollectorName" $collector) }}
  {{- if $.Values.podLogs.lokiReceiver.enabled }}
    {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.podLogs.lokiReceiver.port "portName" "loki" "portProtocol" "TCP") }}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "features.podLogs.receiver.loki" }}
  {{- if and .Values.podLogs.enabled .Values.podLogs.lokiReceiver.enabled }}
http://{{ include "alloy.fullname" (index .Subcharts .Values.podLogs.collector) }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.podLogs.lokiReceiver.port }}
  {{- end }}
{{- end }}
