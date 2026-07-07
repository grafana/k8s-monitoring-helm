{{- define "features.podLogsViaKubernetesApi.enabled" }}{{ .Values.podLogsViaKubernetesApi.enabled }}{{- end }}

{{- define "features.podLogsViaKubernetesApi.include" }}
{{- if .Values.podLogsViaKubernetesApi.enabled -}}
{{- $destinations := include "features.podLogsViaKubernetesApi.destinations" . | fromYamlArray }}

// Feature: Pod Logs via Kubernetes API
{{- include "feature.podLogsViaKubernetesApi.module" (dict "Values" .Values.podLogsViaKubernetesApi "Files" $.Subcharts.podLogsViaKubernetesApi.Files "Template" $.Template) }}
pod_logs_via_kubernetes_api "feature" {
  logs_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "podLogsViaKubernetesApi" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "podLogsViaKubernetesApi" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") }}
{{- end -}}
{{- end -}}

{{- define "features.podLogsViaKubernetesApi.destinations" }}
{{- if .Values.podLogsViaKubernetesApi.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.podLogsViaKubernetesApi.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.podLogsViaKubernetesApi.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.podLogsViaKubernetesApi.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.podLogsViaKubernetesApi.collector.values" }}{{- end -}}

{{- define "features.podLogsViaKubernetesApi.chooseCollector" -}}{{- end -}}

{{- define "features.podLogsViaKubernetesApi.validate" }}
{{- if .Values.podLogsViaKubernetesApi.enabled -}}
{{- $featureKey := "podLogsViaKubernetesApi" }}
{{- $featureName := "Kubernetes Pod logs via Kubernetes API" }}
{{- $destinations := include "features.podLogsViaKubernetesApi.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "featureName" $featureName) }}
{{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "podLogsViaKubernetesApi" "featureName" $featureName "type" "logs" "ecosystem" "loki") }}

{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}

{{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
{{- include "feature.podLogsViaKubernetesApi.collector.validate" (dict "Values" $.Values.podLogsViaKubernetesApi "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}
{{- end -}}
