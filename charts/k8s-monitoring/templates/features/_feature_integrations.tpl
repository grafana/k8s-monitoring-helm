{{- define "features.integrations.enabled" }}
{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- $logRuleIntegrations := include "feature.integrations.configured.logRules" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if or $metricIntegrations $logRuleIntegrations }}true{{ else }}false{{ end }}
{{- end }}

{{- define "features.integrations.metrics.include" }}
{{- $values := dict "Chart" $.Subcharts.integrations.Chart "Values" .Values.integrations "Files" $.Subcharts.integrations.Files "Release" $.Release }}
{{- $metricsDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.integrations.destinations) | fromYamlArray }}
{{- $logsDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.integrations.destinations) | fromYamlArray }}
{{- $metricIntegrations := include "feature.integrations.configured.metrics" $values | fromYamlArray }}
{{- $logOutputIntegrations := include "feature.integrations.configured.logOutput" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- range $integrationType := $metricIntegrations }}
{{- include (printf "integrations.%s.module.metrics" $integrationType) $values | indent 0 }}
{{ include "helper.alloy_name" $integrationType }}_integration "integration" {
  metrics_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "integrations" "destinationNames" $metricsDestinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
{{- if has $integrationType $logOutputIntegrations }}
  logs_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "integrations" "destinationNames" $logsDestinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
{{- end }}
}
{{- end }}
{{- /* Emit the chart-owned pipeline boundary components once for the feature (not per integration), so the shared stamper/sinks/gates aren't duplicated. */}}
{{- if $metricIntegrations }}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "integrations" "destinationNames" $metricsDestinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end }}
{{- if $logOutputIntegrations }}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "integrations" "destinationNames" $logsDestinations "type" "logs" "ecosystem" "loki") }}
{{- end }}
{{- end }}

{{- define "features.integrations.include" }}
  {{ include "features.integrations.metrics.include" . | indent 0 }}
{{- end }}

{{- define "features.integrations.destinations" }}
{{ include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.integrations.destinations) | nindent 0 }}
{{- $logOutputIntegrations := include "feature.integrations.configured.logOutput" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if $logOutputIntegrations }}
  {{ include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.integrations.destinations) | nindent 0 }}
{{- end }}
{{- end }}

{{- define "features.integrations.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{/*{{- $destinations := include "features.integrations.destinations" . | fromYamlArray -}}*/}}
{{/*{{ range $destination := $destinations -}}*/}}
{{/*  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}*/}}
{{/*  {{- if ne $destinationEcosystem "prometheus" -}}*/}}
{{/*    {{- $isTranslating = true -}}*/}}
{{/*  {{- end -}}*/}}
{{/*{{- end -}}*/}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.integrations.logs.discoveryRules" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraDiscoveryRules := list }}
{{- $logIntegrations := include "feature.integrations.configured.logRules" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraDiscoveryRules = append $extraDiscoveryRules ((include (printf "integrations.%s.logs.discoveryRules" $integration) $values) | indent 0) }}
{{- end }}
{{ $extraDiscoveryRules | join "\n" }}
{{- end }}

{{- define "features.integrations.logs.logProcessingStages" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraLogProcessingStages := "" }}
{{- $logIntegrations := include "feature.integrations.configured.logRules" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraLogProcessingStages = cat $extraLogProcessingStages "\n" (include (printf "integrations.%s.logs.processingStage" $integration) $values) | indent 0 }}
{{- end }}
{{ $extraLogProcessingStages }}
{{- end }}

{{- define "features.integrations.collector.values" }}{{ end -}}

{{- define "features.integrations.chooseCollector" -}}{{- end -}}

{{- define "features.integrations.validate" }}
{{- if eq (include "features.integrations.enabled" .) "true" }}
{{- $featureName := "Service Integrations" }}

{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- $destinations := include "features.integrations.destinations" . | fromYamlArray }}
{{- if $metricIntegrations }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "integrations" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}
  {{- $collectorName := $.Values.integrations.collector }}
  {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}
{{- end }}

{{- $logOutputIntegrations := include "feature.integrations.configured.logOutput" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if $logOutputIntegrations }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "featureName" $featureName) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "integrations" "featureName" $featureName "type" "logs" "ecosystem" "loki") }}
{{- end }}

{{- $podLogsEnabled := include "features.podLogsViaLoki.enabled" $ }}
{{- $logIntegrations := include "feature.integrations.configured.logRules" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if and $logIntegrations (ne $podLogsEnabled "true") }}
  {{- $msg := list "" "Service integrations that include logs requires enabling the Pod Logs feature." }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "podLogsViaLoki:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}

{{- include "feature.integrations.validate" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- end }}
{{- end }}
