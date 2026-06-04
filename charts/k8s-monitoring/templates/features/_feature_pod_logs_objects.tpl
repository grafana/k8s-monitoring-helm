{{- define "features.podLogsObjects.enabled" }}{{ .Values.podLogsObjects.enabled }}{{- end }}

{{- define "features.podLogsObjects.include" }}
{{- if .Values.podLogsObjects.enabled -}}
{{- $destinations := include "features.podLogsObjects.destinations" . | fromYamlArray }}

// Feature: PodLogs Objects
{{- include "feature.podLogsObjects.module" (dict "Values" .Values.podLogsObjects "Files" $.Subcharts.podLogsObjects.Files "Template" $.Template) }}
pod_logs_objects "feature" {
  logs_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "podLogsObjects" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "podLogsObjects" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") }}
{{- end -}}
{{- end -}}

{{- define "features.podLogsObjects.destinations" }}
{{- if .Values.podLogsObjects.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.podLogsObjects.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.podLogsObjects.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.podLogsObjects.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.podLogsObjects.collector.values" }}
  {{- if .Values.podLogsObjects.enabled }}
    {{- if .Values.podLogsObjects.nodeFilter }}
      {{- $values := dict }}
      {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" "podLogsObjects") }}
      {{- $extraEnv := deepCopy (dig "alloy" "extraEnv" list (get $.Values.collectors $collectorName)) }}
      {{- $extraEnv = (include "collectors.set_extra_env" (dict "envList" $extraEnv "name" "NODE_NAME" "valueFrom" (dict "fieldRef" (dict "fieldPath" "spec.nodeName")))) | fromYamlArray }}
      {{- $values = $values | merge (dict $collectorName (dict "alloy" (dict "extraEnv" $extraEnv))) }}
      {{- $values | toYaml }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "features.podLogsObjects.chooseCollector" -}}{{- end -}}

{{- define "features.podLogsObjects.validate" }}
{{- if .Values.podLogsObjects.enabled -}}
{{- $featureKey := "podLogsObjects" }}
{{- $featureName := "Alloy PodLogs Objects" }}
{{- $destinations := include "features.podLogsObjects.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "featureName" $featureName) }}
{{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "podLogsObjects" "featureName" $featureName "type" "logs" "ecosystem" "loki") }}

{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}

{{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
{{- include "feature.podLogsObjects.collector.validate" (dict "Values" $.Values.podLogsObjects "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}
{{- end -}}
