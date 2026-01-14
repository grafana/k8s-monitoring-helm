{{- define "features.podLogsObjects.enabled" }}{{ .Values.podLogsObjects.enabled }}{{- end }}

{{- define "features.podLogsObjects.collectors" }}
{{- if .Values.podLogsObjects.enabled -}}
- {{ .Values.podLogsObjects.collector }}
{{- end }}
{{- end }}

{{- define "features.podLogsObjects.include" }}
{{- if .Values.podLogsObjects.enabled -}}
{{- $destinations := include "features.podLogsObjects.destinations" . | fromYamlArray }}

// Feature: PodLogs Objects
{{- include "feature.podLogsObjects.module" (dict "Values" .Values.podLogsObjects "Files" $.Subcharts.podLogsObjects.Files) }}
pod_logs_objects "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.podLogsObjects.destinations" }}
{{- if .Values.podLogsObjects.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.podLogsObjects.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.podLogsObjects.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.podLogsObjects.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.podLogsObjects.collector.values" }}
  {{- if .Values.podLogsObjects.enabled }}
    {{- if .Values.podLogsObjects.nodeFilter }}
      {{- $values := dict }}
      {{- range $collector := include "features.podLogsObjects.collectors" . | fromYamlArray }}
        {{- $extraEnv := deepCopy (dig "alloy" "extraEnv" list (index $.Values $collector)) }}
        {{- if eq (include "collectors.has_extra_env" (deepCopy $ | merge (dict "name" $collector "envVar" "NODE_NAME"))) "false" }}
          {{- $extraEnv = append $extraEnv (dict "name" "NODE_NAME" "valueFrom" (dict "fieldRef" (dict "fieldPath" "spec.nodeName"))) }}
        {{- end }}
        {{- $values = $values | merge (dict $collector (dict "alloy" (dict "extraEnv" $extraEnv))) }}
      {{- end }}
      {{- $values | toYaml }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "features.podLogsObjects.validate" }}
{{- if .Values.podLogsObjects.enabled -}}
{{- $featureName := "Alloy PodLogs Objects" }}
{{- $destinations := include "features.podLogsObjects.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "feature" $featureName) }}

{{- range $collectorName := include "features.podLogsObjects.collectors" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (deepCopy $ | merge (dict "collectorName" $collectorName)) | fromYaml }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collectorName "feature" $featureName) }}
  {{- include "feature.podLogsObjects.collector.validate" (dict "Values" $.Values.podLogsObjects "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}
{{- end -}}
{{- end -}}
