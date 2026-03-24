{{- define "features.clusterEvents.enabled" }}{{ .Values.clusterEvents.enabled }}{{- end }}

{{- define "features.clusterEvents.include" }}
{{- if .Values.clusterEvents.enabled -}}
{{- $destinations := include "features.clusterEvents.destinations" . | fromYamlArray }}
// Feature: Cluster Events
{{- include "feature.clusterEvents.module" (dict "Values" $.Values.clusterEvents "Files" $.Subcharts.clusterEvents.Files) }}
cluster_events "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
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
{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- end -}}
{{- end -}}
