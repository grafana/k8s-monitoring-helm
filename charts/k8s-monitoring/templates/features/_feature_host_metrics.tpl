{{- define "features.hostMetrics.enabled" }}{{ .Values.hostMetrics.enabled }}{{- end }}

{{- define "features.hostMetrics.include" }}
{{- if .Values.hostMetrics.enabled -}}
{{- $destinations := include "features.hostMetrics.destinations" . | fromYamlArray }}
// Feature: Host Metrics
{{- include "feature.hostMetrics.module" (dict "Values" $.Values.hostMetrics "Files" $.Subcharts.hostMetrics.Files "Release" $.Release "telemetryServices" $.Values.telemetryServices) }}
host_metrics "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics.destinations" }}
{{- if .Values.hostMetrics.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.hostMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.hostMetrics.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.hostMetrics.collector.values" }}{{- end -}}

{{- define "features.hostMetrics.chooseCollector" -}}{{- end -}}

{{- define "features.hostMetrics.validate" }}
{{- if .Values.hostMetrics.enabled }}
  {{- $featureKey := "hostMetrics" }}
  {{- $featureName := "Kubernetes Host metrics" }}
  {{- $destinations := include "features.hostMetrics.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName) }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
  {{- /* Scraping external exporters (Node Exporter, Windows Exporter, Kepler) distributes targets across the
         collector cluster and so requires clustering. The Alloy source instead collects host metrics locally on a
         DaemonSet, so it does not. Only skip the clustering check when nothing that scrapes external exporters is
         enabled. */}}
  {{- $needsClustering := false }}
  {{- if and $.Values.hostMetrics.linuxHosts.enabled (ne ($.Values.hostMetrics.linuxHosts.source | default "node-exporter") "alloy") }}{{- $needsClustering = true }}{{- end }}
  {{- if $.Values.hostMetrics.windowsHosts.enabled }}{{- $needsClustering = true }}{{- end }}
  {{- if $.Values.hostMetrics.energyMetrics.enabled }}{{- $needsClustering = true }}{{- end }}
  {{- if $needsClustering }}
  {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}
  {{- end }}

  {{- include "feature.hostMetrics.validate" (dict "Values" $.Values.hostMetrics "telemetryServices" $.Values.telemetryServices) }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- include "feature.hostMetrics.collector.validate" (dict "Values" $.Values.hostMetrics "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end }}
{{- end }}
