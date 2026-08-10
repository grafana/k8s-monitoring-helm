{{- define "features.hostMetrics_windowsHosts.enabled" }}{{ and .Values.hostMetrics.enabled .Values.hostMetrics.windowsHosts.enabled }}{{- end }}

{{- define "features.hostMetrics_windowsHosts.include" }}
{{- if eq (include "features.hostMetrics_windowsHosts.enabled" .) "true" }}
{{- $destinations := include "features.hostMetrics_windowsHosts.destinations" . | fromYamlArray }}
// Feature: Host Metrics - Windows Hosts
{{- include "feature.hostMetrics.windowsHosts.module" (dict "Values" $.Values.hostMetrics "Files" $.Subcharts.hostMetrics.Files "Release" $.Release "telemetryServices" $.Values.telemetryServices) }}
windows_host_metrics "feature" {
  metrics_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "hostMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- if eq (include "features.hostMetrics.pipelineOwner" $) "windowsHosts" }}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "hostMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics_windowsHosts.destinations" }}
{{- if eq (include "features.hostMetrics_windowsHosts.enabled" .) "true" }}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.hostMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics_windowsHosts.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.hostMetrics_windowsHosts.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.hostMetrics_windowsHosts.collector.values" }}
{{- if eq (include "features.hostMetrics_windowsHosts.enabled" .) "true" }}
  {{- $values := dict }}
  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" "hostMetrics_windowsHosts") }}
  {{- $extraEnv := deepCopy (dig "alloy" "extraEnv" list (get $.Values.collectors $collectorName)) }}
  {{- $extraEnv = (include "collectors.set_extra_env" (dict "envList" $extraEnv "name" "NODE_NAME" "valueFrom" (dict "fieldRef" (dict "fieldPath" "spec.nodeName")))) | fromYamlArray }}
  {{- $values = $values | merge (dict $collectorName (dict "alloy" (dict "extraEnv" $extraEnv))) }}
  {{- $values | toYaml }}
{{- end }}
{{- end -}}

{{- define "features.hostMetrics_windowsHosts.validate" }}
{{- if eq (include "features.hostMetrics_windowsHosts.enabled" .) "true" }}
  {{- $featureName := "Kubernetes Host metrics - Windows Hosts" }}
  {{- $destinations := include "features.hostMetrics_windowsHosts.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "hostMetrics" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" "hostMetrics_windowsHosts") }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" "hostMetrics" "featureName" $featureName) }}
  {{- /* Scraping an external Windows Exporter distributes targets across the collector cluster and so
         requires clustering. The Alloy source instead collects host metrics locally on a DaemonSet,
         so it does not. */}}
  {{- if ne ($.Values.hostMetrics.windowsHosts.source | default "windows-exporter") "alloy" }}
    {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}
  {{- end }}

  {{- include "feature.hostMetrics.windowsHosts.validate" (dict "Values" $.Values.hostMetrics "telemetryServices" $.Values.telemetryServices) }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- include "feature.hostMetrics.windowsHosts.collector.validate" (dict "Values" $.Values.hostMetrics "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end }}
{{- end }}
