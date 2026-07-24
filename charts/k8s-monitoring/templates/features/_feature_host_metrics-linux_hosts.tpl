{{- define "features.hostMetrics_linuxHosts.enabled" }}{{ and .Values.hostMetrics.enabled .Values.hostMetrics.linuxHosts.enabled }}{{- end }}

{{- define "features.hostMetrics_linuxHosts.include" }}
{{- if eq (include "features.hostMetrics_linuxHosts.enabled" .) "true" }}
{{- $destinations := include "features.hostMetrics_linuxHosts.destinations" . | fromYamlArray }}
// Feature: Host Metrics - Linux Hosts
{{- include "feature.hostMetrics.linuxHosts.module" (dict "Values" $.Values.hostMetrics "Files" $.Subcharts.hostMetrics.Files "Release" $.Release "telemetryServices" $.Values.telemetryServices) }}
linux_host_metrics "feature" {
  metrics_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "hostMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- if eq (include "features.hostMetrics.pipelineOwner" $) "linuxHosts" }}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "hostMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics_linuxHosts.destinations" }}
{{- if eq (include "features.hostMetrics_linuxHosts.enabled" .) "true" }}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.hostMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics_linuxHosts.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.hostMetrics_linuxHosts.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.hostMetrics_linuxHosts.collector.values" }}{{- end -}}

{{- define "features.hostMetrics_linuxHosts.validate" }}
{{- if eq (include "features.hostMetrics_linuxHosts.enabled" .) "true" }}
  {{- $featureName := "Kubernetes Host metrics - Linux Hosts" }}
  {{- $destinations := include "features.hostMetrics_linuxHosts.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "hostMetrics" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" "hostMetrics_linuxHosts") }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" "hostMetrics" "featureName" $featureName) }}
  {{- /* Scraping an external Node Exporter distributes targets across the collector cluster and so
         requires clustering. The Alloy source instead collects host metrics locally on a DaemonSet,
         so it does not. */}}
  {{- if ne ($.Values.hostMetrics.linuxHosts.source | default "node-exporter") "alloy" }}
    {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}
  {{- end }}

  {{- include "feature.hostMetrics.linuxHosts.validate" (dict "Values" $.Values.hostMetrics "telemetryServices" $.Values.telemetryServices) }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- include "feature.hostMetrics.linuxHosts.collector.validate" (dict "Values" $.Values.hostMetrics "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end }}
{{- end }}
