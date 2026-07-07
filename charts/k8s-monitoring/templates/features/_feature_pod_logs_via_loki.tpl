{{- define "features.podLogsViaLoki.enabled" }}{{ .Values.podLogsViaLoki.enabled }}{{- end }}

{{- define "features.podLogsViaLoki.include" }}
{{- if .Values.podLogsViaLoki.enabled -}}
{{- $extraDiscoveryRulesFromIntegrations := cat (include "features.integrations.logs.discoveryRules" .) "\n" .Values.podLogsViaLoki.extraDiscoveryRules | trim }}
{{- $extraLogProcessingStagesFromIntegrations := cat (include "features.integrations.logs.logProcessingStages" .) "\n" .Values.podLogsViaLoki.extraLogProcessingStages | trim }}
{{- $values := mergeOverwrite .Values.podLogsViaLoki (dict "extraDiscoveryRules" $extraDiscoveryRulesFromIntegrations "extraLogProcessingStages" $extraLogProcessingStagesFromIntegrations) }}
{{- $destinations := include "features.podLogsViaLoki.destinations" . | fromYamlArray }}

// Feature: Pod Logs (Loki)
{{- include "feature.podLogsViaLoki.module" (dict "Values" $values "Files" $.Subcharts.podLogsViaLoki.Files "Template" $.Template) }}
pod_logs_via_loki "feature" {
  logs_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "podLogsViaLoki" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "podLogsViaLoki" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") }}
{{- end -}}
{{- end -}}

{{- define "features.podLogsViaLoki.destinations" }}
{{- if .Values.podLogsViaLoki.enabled -}}
  {{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.podLogsViaLoki.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.podLogsViaLoki.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.podLogsViaLoki.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.podLogsViaLoki.collector.values" }}{{- end -}}

{{- define "features.podLogsViaLoki.chooseCollector" -}}{{- end -}}

{{- define "features.podLogsViaLoki.validate" }}
{{- if .Values.podLogsViaLoki.enabled -}}
{{- $featureKey := "podLogsViaLoki" }}
{{- $featureName := "Kubernetes Pod logs" }}
{{- $destinations := include "features.podLogsViaLoki.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "featureName" $featureName) }}
{{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" $featureKey "featureName" $featureName "type" "logs" "ecosystem" "loki") }}

{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
{{- include "feature.podLogsViaLoki.collector.validate" (dict "Values" $.Values.podLogsViaLoki "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}
{{- end -}}
