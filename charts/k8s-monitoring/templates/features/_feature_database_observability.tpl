{{- define "features.databaseObservability.enabled" }}
{{- $metricIntegrations := include "feature.databaseObservability.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- $logIntegrations := include "feature.databaseObservability.configured.logs" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if or $metricIntegrations $logIntegrations }}true{{ else }}false{{ end }}
{{- end }}

{{- define "features.databaseObservability.collectors" }}
{{- $metricIntegrations := include "feature.databaseObservability.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if (not (empty $metricIntegrations)) }}
- {{ .Values.integrations.collector }}
{{- end }}
{{- end }}

{{- define "features.databaseObservability.metrics.include" }}
{{- $values := dict "Chart" $.Subcharts.integrations.Chart "Values" .Values.integrations "Files" $.Subcharts.integrations.Files "Release" $.Release }}
{{- $destinations := include "features.databaseObservability.destinations" . | fromYamlArray }}
{{- $integrations := include "feature.databaseObservability.configured.metrics" $values | fromYamlArray }}
{{- range $integrationType := $integrations }}
{{- include (printf "integrations.%s.module.metrics" $integrationType) $values | indent 0 }}
{{ include "helper.alloy_name" $integrationType }}_integration "integration" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end }}
{{- end }}

{{- define "features.databaseObservability.include" }}
{{- if eq .collectorName .Values.databaseObservability.collector }}
  {{ include "features.databaseObservability.metrics.include" . | indent 0 }}
{{- end }}
{{- end }}

{{- define "features.databaseObservability.destinations" }}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.integrations.destinations) -}}
{{- end }}

{{- define "features.databaseObservability.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.databaseObservability.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.databaseObservability.logs.discoveryRules" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraDiscoveryRules := list }}
{{- $logIntegrations := include "feature.integrations.configured.logs" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraDiscoveryRules = append $extraDiscoveryRules ((include (printf "integrations.%s.logs.discoveryRules" $integration) $values) | indent 0) }}
{{- end }}
{{ $extraDiscoveryRules | join "\n" }}
{{- end }}

{{- define "features.databaseObservability.logs.logProcessingStages" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraLogProcessingStages := "" }}
{{- $logIntegrations := include "feature.integrations.configured.logs" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraLogProcessingStages = cat $extraLogProcessingStages "\n" (include (printf "integrations.%s.logs.processingStage" $integration) $values) | indent 0 }}
{{- end }}
{{ $extraLogProcessingStages }}
{{- end }}

{{- define "features.databaseObservability.collector.values" }}{{- end -}}

{{- define "features.databaseObservability.validate" }}
{{- if eq (include "features.databaseObservability.enabled" .) "true" }}
{{- $featureName := "Service Integrations" }}

{{- $metricIntegrations := include "feature.databaseObservability.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if $metricIntegrations }}
  {{- $metricDestinations := include "features.databaseObservability.destinations" . | fromYamlArray }}
  {{- include "destinations.validate_destination_list" (dict "destinations" $metricDestinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
{{- end }}

{{- $podLogsEnabled := include "features.podLogs.enabled" $ }}
{{- $logIntegrations := include "feature.databaseObservability.configured.logs" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if and $logIntegrations (ne $podLogsEnabled "true") }}
  {{- $msg := list "" "Service integrations that include logs requires enabling the Pod Logs feature." }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "podLogs:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}

{{- include "feature.databaseObservability.validate" (dict "Values" $.Values.databaseObservability) }}
{{- end }}
{{- end }}
