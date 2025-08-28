{{- define "features.databaseObservability.enabled" }}
{{- $mysqlInstances := .Values.databaseObservability.mysql.instances }}
{{- if $mysqlInstances }}true{{ else }}false{{ end }}
{{- end }}

{{- define "features.databaseObservability.collectors" }}
- {{ .Values.databaseObservability.collector }}
{{- end }}

{{- define "features.databaseObservability.include" }}
{{- if eq (include "features.databaseObservability.enabled" .) "true" }}
{{- $destinations := include "features.databaseObservability.destinations" . | fromYamlArray }}
{{- include "feature.databaseObservability.module" (dict "Values" $.Values.databaseObservability "Files" $.Subcharts.databaseObservability.Files "Release" $.Release) }}
db_observability "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- end }}
{{- end }}

{{- define "features.databaseObservability.destinations" }}
{{/*TODO: determine if we need metrics *and-or* logs destinations*/}}
{{ include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.databaseObservability.destinations) }}
{{ include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.databaseObservability.destinations) }}
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

{{/*{{- define "features.databaseObservability.logs.discoveryRules" }}*/}}
{{/*{{- $values := (dict "Values" .Values.databaseObservability "Files" $.Subcharts.databaseObservability.Files) }}*/}}
{{/*{{- $extraDiscoveryRules := list }}*/}}
{{/*{{- $logIntegrations := include "feature.databaseObservability.configured.logs" $values | fromYamlArray }}*/}}
{{/*{{- range $integration := $logIntegrations }}*/}}
{{/*  {{- $extraDiscoveryRules = append $extraDiscoveryRules ((include (printf "integrations.%s.logs.discoveryRules" $integration) $values) | indent 0) }}*/}}
{{/*{{- end }}*/}}
{{/*{{ $extraDiscoveryRules | join "\n" }}*/}}
{{/*{{- end }}*/}}

{{/*{{- define "features.databaseObservability.logs.logProcessingStages" }}*/}}
{{/*{{- $values := (dict "Values" .Values.databaseObservability "Files" $.Subcharts.databaseObservability.Files) }}*/}}
{{/*{{- $extraLogProcessingStages := "" }}*/}}
{{/*{{- $logIntegrations := include "feature.integrations.configured.logs" $values | fromYamlArray }}*/}}
{{/*{{- range $integration := $logIntegrations }}*/}}
{{/*  {{- $extraLogProcessingStages = cat $extraLogProcessingStages "\n" (include (printf "integrations.%s.logs.processingStage" $integration) $values) | indent 0 }}*/}}
{{/*{{- end }}*/}}
{{/*{{ $extraLogProcessingStages }}*/}}
{{/*{{- end }}*/}}

{{- define "features.databaseObservability.collector.values" }}{{- end -}}

{{- define "features.databaseObservability.validate" }}
{{- if eq (include "features.databaseObservability.enabled" .) "true" }}
{{- $featureName := "Database Observability" }}

{{- $metricDestinations := include "features.databaseObservability.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $metricDestinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}

{{- $podLogsEnabled := include "features.podLogs.enabled" $ }}
{{/*{{- $logsEnabled := include "feature.databaseObservability.configured.logs" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}*/}}
{{/*{{- if and $logIntegrations (ne $podLogsEnabled "true") }}*/}}
{{/*  {{- $msg := list "" "Service integrations that include logs requires enabling the Pod Logs feature." }}*/}}
{{/*  {{- $msg = append $msg "Please set:" }}*/}}
{{/*  {{- $msg = append $msg "podLogs:" }}*/}}
{{/*  {{- $msg = append $msg "  enabled: true" }}*/}}
{{/*  {{- fail (join "\n" $msg) }}*/}}
{{/*{{- end }}*/}}

{{- range $collectorName := include "features.databaseObservability.collectors" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (deepCopy $ | merge (dict "collectorName" $collectorName)) | fromYaml }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collectorName "feature" $featureName) }}
  {{- include "feature.databaseObservability.collector.validate" (dict "Values" $.Values.databaseObservability "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}

{{- include "feature.databaseObservability.validate" (dict "Values" $.Values.databaseObservability) }}
{{- end }}
{{- end }}
