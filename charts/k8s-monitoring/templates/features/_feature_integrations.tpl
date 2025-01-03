{{- define "features.integrations.enabled" }}
{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- $logIntegrations := include "feature.integrations.configured.logs" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if or $metricIntegrations $logIntegrations }}true{{ else }}false{{ end }}
{{- end }}

{{- define "features.integrations.collectors" }}
{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations) | fromYamlArray }}
{{- if (not (empty $metricIntegrations)) }}
- {{ .Values.integrations.collector }}
{{- end }}
{{- end }}

{{- define "features.integrations.metrics.include" }}
{{- $values := dict "Chart" $.Subcharts.integrations.Chart "Values" .Values.integrations "Files" $.Subcharts.integrations.Files "Release" $.Release }}
{{- $destinations := include "features.integrations.destinations" . | fromYamlArray }}
{{- $integrations := include "feature.integrations.configured.metrics" $values | fromYamlArray }}
{{- range $integrationType := $integrations }}
{{- include (printf "integrations.%s.module.metrics" $integrationType) $values | indent 0 }}
{{ include "helper.alloy_name" $integrationType }}_integration "integration" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end }}
{{- end }}

{{- define "features.integrations.include" }}
{{- if eq .collectorName .Values.integrations.collector }}
  {{ include "features.integrations.metrics.include" . | indent 0 }}
{{- end }}
{{- end }}

{{- define "features.integrations.destinations" }}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.integrations.destinations) -}}
{{- end }}

{{- define "features.integrations.logs.discoveryRules" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraDiscoveryRules := list }}
{{- $logIntegrations := include "feature.integrations.configured.logs" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraDiscoveryRules = append $extraDiscoveryRules ((include (printf "integrations.%s.logs.discoveryRules" $integration) $values) | indent 0) }}
{{- end }}
{{ $extraDiscoveryRules | join "\n" }}
{{- end }}

{{- define "features.integrations.logs.logProcessingStages" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraLogProcessingStages := "" }}
{{- $logIntegrations := include "feature.integrations.configured.logs" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraLogProcessingStages = cat $extraLogProcessingStages "\n" (include (printf "integrations.%s.logs.processingStage" $integration) $values) | indent 0 }}
{{- end }}
{{ $extraLogProcessingStages }}
{{- end }}

{{- define "features.integrations.validate" }}
{{- if eq (include "features.integrations.enabled" .) "true" }}
{{- $featureName := "Service Integrations" }}

{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if $metricIntegrations }}
  {{- $metricDestinations := include "features.integrations.destinations" . | fromYamlArray }}
  {{- include "destinations.validate_destination_list" (dict "destinations" $metricDestinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
{{- end }}

{{- $podLogsEnabled := include "features.podLogs.enabled" $ }}
{{- $logIntegrations := include "feature.integrations.configured.logs" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if and $logIntegrations (ne $podLogsEnabled "true") }}
  {{- $msg := list "" "Service integrations that include logs requires enabling the Pod Logs feature." }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "podLogs:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}

{{- include "feature.integrations.validate" (dict "Values" $.Values.integrations) }}
{{- end }}
{{- end }}
