{{/* Determines if this feature is enabled based on the presence of configured database instances. */}}
{{- define "features.databaseObservability.enabled" }}
{{- $mysqlInstances := .Values.databaseObservability.mysql.instances }}
{{- $postgresqlInstances := .Values.databaseObservability.postgresql.instances }}
{{- if or $mysqlInstances $postgresqlInstances }}true{{ else }}false{{ end }}
{{- end }}

{{- define "features.databaseObservability.collectors" }}
- {{ .Values.databaseObservability.collector }}
{{- end }}

{{/* The main template to include the Database Observability configuration components in the Alloy ConfigMap. */}}
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

{{/* Returns the list of destinations (metrics and logs) that will be utilized for Database Observability. */}}
{{- define "features.databaseObservability.destinations" }}
{{/*TODO: determine if we need metrics *and-or* logs destinations. We only need logs if queryAnalysis is used, we only need metrics if the exporter and/or query analaysis. */}}
{{ include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.databaseObservability.destinations) }}
{{ include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.databaseObservability.destinations) }}
{{- end }}

{{/* Determines if any of the configured destinations require translation (i.e., are not Prometheus or Loki). */}}
{{- define "features.databaseObservability.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.databaseObservability.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if and (ne $destinationEcosystem "prometheus") (ne $destinationEcosystem "loki") -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{/* Returns the Alloy rules that will be used in the `podLogs` feature during log discovery for Database Observability. */}}
{{- define "features.databaseObservability.logs.discoveryRules" }}
{{- $values := (dict "Values" .Values.databaseObservability "Files" $.Subcharts.databaseObservability.Files) }}
{{- $logIntegrations := include "feature.databaseObservability.configured.logs" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- (include (printf "databaseObservability.%s.logs.discoveryRules" $integration) $values) | nindent 0 }}
{{- end }}
{{- end }}

{{/* Returns the log processing rules that will be used in the `podLogs` feature during log processing for Database Observability. */}}
{{- define "features.databaseObservability.logs.logProcessingStages" }}
{{- $values := (dict "Values" .Values.databaseObservability "Files" $.Subcharts.databaseObservability.Files) }}
{{- $logEnabledDatabases := include "feature.databaseObservability.configured.logs" $values | fromYamlArray }}
{{- range $database := $logEnabledDatabases }}
  {{- include (printf "databaseObservability.%s.logs.processingStage" $database) $values | nindent 0 }}
{{- end }}
{{- end }}

{{/* This feature does not add any additional values to the Alloy instances. */}}
{{- define "features.databaseObservability.collector.values" }}{{- end -}}

{{/* Validations for the Database Observability feature. */}}
{{- define "features.databaseObservability.validate" }}
{{- if eq (include "features.databaseObservability.enabled" .) "true" }}
{{- $featureName := "Database Observability" }}

{{/* TODO: We need to check for both metric and log destinations. Pete will fix */}}
{{- $destinations := include "features.databaseObservability.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}

{{- $podLogsEnabled := include "features.podLogs.enabled" $ }}
{{- $logsEnabled := include "feature.databaseObservability.configured.logs" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if and $logsEnabled (ne $podLogsEnabled "true") }}
  {{- $msg := list "" "Service integrations that include logs requires enabling the Pod Logs feature." }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "podLogs:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}

{{- range $collectorName := include "features.databaseObservability.collectors" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (deepCopy $ | merge (dict "collectorName" $collectorName)) | fromYaml }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collectorName "feature" $featureName) }}
  {{- include "feature.databaseObservability.collector.validate" (dict "Values" $.Values.databaseObservability "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}

{{- include "feature.databaseObservability.validate" (dict "Values" $.Values.databaseObservability) }}
{{- end }}
{{- end }}
