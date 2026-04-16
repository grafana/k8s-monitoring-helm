{{- define "features.costMetrics.enabled" }}{{ .Values.costMetrics.enabled }}{{- end }}

{{- define "features.costMetrics.include" }}
{{- if .Values.costMetrics.enabled -}}
{{- $destinations := include "features.costMetrics.destinations" . | fromYamlArray }}
// Feature: Cost Metrics
{{- include "feature.costMetrics.module" (dict "Values" $.Values.costMetrics "Files" $.Subcharts.clusterMetrics.Files "Release" $.Release "telemetryServices" $.Values.telemetryServices) }}
cost_metrics "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.costMetrics.destinations" }}
{{- if .Values.costMetrics.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.costMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.costMetrics.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.costMetrics.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.costMetrics.collector.values" }}{{- end -}}

{{- define "features.costMetrics.chooseCollector" -}}{{- end -}}

{{- define "features.costMetrics.validate" }}
{{- if .Values.costMetrics.enabled }}
  {{- $featureKey := "costMetrics" }}
  {{- $featureName := "Kubernetes Cluster metrics" }}
  {{- $destinations := include "features.costMetrics.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName) }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
  {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}

  {{- include "feature.costMetrics.validate" (dict "Values" $.Values.costMetrics "telemetryServices" $.Values.telemetryServices) }}
{{- end }}
{{- end }}
