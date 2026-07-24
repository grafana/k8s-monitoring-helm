{{- define "features.hostMetrics_energyMetrics.enabled" }}{{ and .Values.hostMetrics.enabled .Values.hostMetrics.energyMetrics.enabled }}{{- end }}

{{- define "features.hostMetrics_energyMetrics.include" }}
{{- if eq (include "features.hostMetrics_energyMetrics.enabled" .) "true" }}
{{- $destinations := include "features.hostMetrics_energyMetrics.destinations" . | fromYamlArray }}
// Feature: Host Metrics - Energy Metrics
{{- include "feature.hostMetrics.energyMetrics.module" (dict "Values" $.Values.hostMetrics "Files" $.Subcharts.hostMetrics.Files "Release" $.Release "telemetryServices" $.Values.telemetryServices) }}
energy_metrics "feature" {
  metrics_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "hostMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- if eq (include "features.hostMetrics.pipelineOwner" $) "energyMetrics" }}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "hostMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics_energyMetrics.destinations" }}
{{- if eq (include "features.hostMetrics_energyMetrics.enabled" .) "true" }}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.hostMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics_energyMetrics.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.hostMetrics_energyMetrics.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.hostMetrics_energyMetrics.collector.values" }}{{- end -}}

{{- define "features.hostMetrics_energyMetrics.validate" }}
{{- if eq (include "features.hostMetrics_energyMetrics.enabled" .) "true" }}
  {{- $featureName := "Kubernetes Host metrics - Energy Metrics" }}
  {{- $destinations := include "features.hostMetrics_energyMetrics.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "hostMetrics" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" "hostMetrics_energyMetrics") }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" "hostMetrics" "featureName" $featureName) }}
  {{- /* Scraping an external Kepler distributes targets across the collector cluster and so requires
         clustering. */}}
  {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}

  {{- include "feature.hostMetrics.energyMetrics.validate" (dict "Values" $.Values.hostMetrics "telemetryServices" $.Values.telemetryServices) }}
{{- end }}
{{- end }}
