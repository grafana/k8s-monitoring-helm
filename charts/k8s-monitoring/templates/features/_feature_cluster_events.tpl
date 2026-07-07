{{- define "features.clusterEvents.enabled" }}{{ .Values.clusterEvents.enabled }}{{- end }}

{{- define "features.clusterEvents.include" }}
{{- if .Values.clusterEvents.enabled -}}
{{- $destinations := include "features.clusterEvents.destinations" . | fromYamlArray }}
// Feature: Cluster Events
{{- include "feature.clusterEvents.module" (dict "Values" $.Values.clusterEvents "Files" $.Subcharts.clusterEvents.Files "Template" $.Template) }}
cluster_events "feature" {
  logs_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "clusterEvents" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "clusterEvents" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") }}
{{- end -}}
{{- end -}}

{{- define "features.clusterEvents.destinations" }}
{{- if .Values.clusterEvents.enabled -}}
  {{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.clusterEvents.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.clusterEvents.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.clusterEvents.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.clusterEvents.collector.values" }}{{- end -}}

{{- define "features.clusterEvents.chooseCollector" -}}{{- end -}}

{{- define "features.clusterEvents.validate" }}
{{- if .Values.clusterEvents.enabled -}}
{{- $featureKey := "clusterEvents" }}
{{- $featureName := "Kubernetes Cluster events" }}
{{- $destinationNames := include "features.clusterEvents.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinationNames "type" "logs" "ecosystem" "loki" "featureName" $featureName) }}
{{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "clusterEvents" "featureName" $featureName "type" "logs" "ecosystem" "loki") }}
{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- if $.Values.clusterEvents.clustering }}
{{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}
{{- end }}
{{- end -}}
{{- end -}}
