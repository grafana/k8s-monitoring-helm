{{- define "features.podLogs.enabled" }}{{ .Values.podLogs.enabled }}{{- end }}

{{- define "features.podLogs.include" }}
{{- if .Values.podLogs.enabled -}}
{{- $extraDiscoveryRulesFromIntegrations := cat (include "features.integrations.logs.discoveryRules" .) "\n" .Values.podLogs.extraDiscoveryRules | trim }}
{{- $extraLogProcessingStagesFromIntegrations := cat (include "features.integrations.logs.logProcessingStages" .) "\n" .Values.podLogs.extraLogProcessingStages | trim }}
{{- $values := mergeOverwrite .Values.podLogs (dict "extraDiscoveryRules" $extraDiscoveryRulesFromIntegrations "extraLogProcessingStages" $extraLogProcessingStagesFromIntegrations) }}
{{- $destinations := include "features.podLogs.destinations" . | fromYamlArray }}

// Feature: Pod Logs
{{- include "feature.podLogs.module" (dict "Values" $values "Files" $.Subcharts.podLogs.Files) }}
pod_logs "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.podLogs.destinations" }}
{{- if .Values.podLogs.enabled -}}
  {{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.podLogs.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.podLogs.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.podLogs.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.podLogs.collector.values" }}{{- end -}}

{{- define "features.podLogs.chooseCollector" -}}{{- end -}}

{{- define "features.podLogs.validate" }}
{{- if .Values.podLogs.enabled -}}
{{- $featureKey := "podLogs" }}
{{- $featureName := "Kubernetes Pod logs" }}
{{- $destinations := include "features.podLogs.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "featureName" $featureName) }}

{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
{{- include "feature.podLogs.collector.validate" (dict "Values" $.Values.podLogs "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}
{{- end -}}
