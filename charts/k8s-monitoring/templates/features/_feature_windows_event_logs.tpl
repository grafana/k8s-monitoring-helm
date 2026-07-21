{{- define "features.windowsEventLogs.enabled" }}{{ .Values.windowsEventLogs.enabled }}{{- end }}

{{- define "features.windowsEventLogs.include" }}
{{- if .Values.windowsEventLogs.enabled -}}
{{- $destinations := include "features.windowsEventLogs.destinations" . | fromYamlArray }}

// Feature: Windows Event Logs
{{- include "feature.windowsEventLogs.module" (dict "Values" .Values.windowsEventLogs "Files" $.Subcharts.windowsEventLogs.Files "Template" $.Template) }}
windows_event_logs "feature" {
  logs_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "windowsEventLogs" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "windowsEventLogs" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") }}
{{- end -}}
{{- end -}}

{{- define "features.windowsEventLogs.destinations" }}
{{- if .Values.windowsEventLogs.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.windowsEventLogs.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.windowsEventLogs.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.windowsEventLogs.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- /* Adds a hostPath volume and mount so each Windows Node's Alloy Pod can persist its event log bookmarks. */ -}}
{{- define "features.windowsEventLogs.collector.values" }}
{{- if and .Values.windowsEventLogs.enabled .Values.windowsEventLogs.bookmarks.enabled }}
  {{- $values := dict }}
  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" "windowsEventLogs") }}
  {{- if $collectorName }}
    {{- $bookmarkPath := $.Values.windowsEventLogs.bookmarks.hostPath }}
    {{- $collectorValues := (include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml) }}
    {{- $mounts := deepCopy (dig "alloy" "mounts" "extra" list $collectorValues) }}
    {{- $mounts = append $mounts (dict "name" "windowsevent-bookmarks" "mountPath" $bookmarkPath) }}
    {{- $volumes := deepCopy (dig "controller" "volumes" "extra" list $collectorValues) }}
    {{- $volumes = append $volumes (dict "name" "windowsevent-bookmarks" "hostPath" (dict "path" $bookmarkPath "type" "DirectoryOrCreate")) }}
    {{- $values = $values | merge (dict "collectors" (dict $collectorName (dict "alloy" (dict "mounts" (dict "extra" $mounts)) "controller" (dict "volumes" (dict "extra" $volumes))))) }}
    {{- $values | toYaml }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "features.windowsEventLogs.chooseCollector" -}}{{- end -}}

{{- define "features.windowsEventLogs.validate" }}
{{- if .Values.windowsEventLogs.enabled -}}
{{- $featureKey := "windowsEventLogs" }}
{{- $featureName := "Windows Event logs" }}
{{- include "feature.windowsEventLogs.validate" (dict "Values" $.Values.windowsEventLogs) }}
{{- $destinations := include "features.windowsEventLogs.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "featureName" $featureName) }}
{{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "windowsEventLogs" "featureName" $featureName "type" "logs" "ecosystem" "loki") }}

{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
{{- include "feature.windowsEventLogs.collector.validate" (dict "Values" $.Values.windowsEventLogs "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}
{{- end -}}
