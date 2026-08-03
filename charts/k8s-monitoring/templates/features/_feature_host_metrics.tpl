{{/* Shared helpers for the Host Metrics sub-features (linuxHosts, windowsHosts, energyMetrics).

     Each sub-feature is registered as its own entry in features.list ("hostMetrics_linuxHosts",
     "hostMetrics_windowsHosts", "hostMetrics_energyMetrics") so it can be routed to its own
     collector. They share the parent `hostMetrics` values for destinations and dataProcessors, so
     the pipeline helpers below are always called with featureKey "hostMetrics". */}}

{{/* Returns the sub-feature key ("linuxHosts" / "windowsHosts" / "energyMetrics") that owns the
     shared dataProcessor pipeline (stamper, processor config slices, destination gates) on the
     collector currently being rendered. When more than one sub-feature lands on the same collector,
     only the owner renders those shared components, so they are never defined more than once.
     Inputs: . (root object, including .Values and .collectorName). */}}
{{- define "features.hostMetrics.pipelineOwner" -}}
{{- $root := . -}}
{{- $owner := "" -}}
{{- range $sub := (list "linuxHosts" "windowsHosts" "energyMetrics") -}}
  {{- if not $owner -}}
    {{- $subValues := get $root.Values.hostMetrics $sub | default dict -}}
    {{- if and $root.Values.hostMetrics.enabled (dig "enabled" false $subValues) -}}
      {{- $effective := include "collectors.getCollectorForFeature" (dict "Values" $root.Values "featureKey" (printf "hostMetrics_%s" $sub)) | trim -}}
      {{- if eq $effective $root.collectorName -}}
        {{- $owner = $sub -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $owner -}}
{{- end -}}

{{/* Aggregate destinations for the whole Host Metrics feature. The individual sub-features are routed
     independently, but the NOTES output reports at the subchart level, so it needs a feature-level view
     of the destinations. */}}
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
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName "Values" $.Values "featureKey" $featureKey) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "hostMetrics" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}

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
