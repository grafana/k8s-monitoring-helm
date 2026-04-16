{{- define "features.clusterMetrics.enabled" }}{{ .Values.clusterMetrics.enabled }}{{- end }}

{{- define "features.clusterMetrics.include" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray }}
// Feature: Cluster Metrics
{{- include "feature.clusterMetrics.module" (dict "Values" $.Values.clusterMetrics "Files" $.Subcharts.clusterMetrics.Files "Release" $.Release "telemetryServices" $.Values.telemetryServices) }}
cluster_metrics "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.clusterMetrics.destinations" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.clusterMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.clusterMetrics.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.clusterMetrics.collector.values" }}{{- end -}}

{{- define "features.clusterMetrics.chooseCollector" -}}{{- end -}}

{{- define "features.clusterMetrics.validate" }}
{{- if .Values.clusterMetrics.enabled }}
  {{- $featureKey := "clusterMetrics" }}
  {{- $featureName := "Kubernetes Cluster metrics" }}
  {{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName) }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
  {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}

  {{- include "feature.clusterMetrics.validate" (dict "Values" $.Values.clusterMetrics "telemetryServices" $.Values.telemetryServices) }}
{{- end }}
{{- end }}
