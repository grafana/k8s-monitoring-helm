{{- define "features.lokiLogsReceiver.enabled" }}{{ .Values.lokiLogsReceiver.enabled }}{{- end }}

{{- define "features.lokiLogsReceiver.include" }}
{{- if .Values.lokiLogsReceiver.enabled -}}
{{- $destinations := include "features.lokiLogsReceiver.destinations" . | fromYamlArray }}
// Feature: Loki Logs Receiver
{{- include "feature.lokiLogsReceiver.module" (dict "Values" $.Values.lokiLogsReceiver "Files" $.Subcharts.lokiLogsReceiver.Files) }}
loki_logs_receiver "feature" {
  logs_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "lokiLogsReceiver" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "lokiLogsReceiver" "destinationNames" $destinations "type" "logs" "ecosystem" "loki") }}
{{- end -}}
{{- end -}}

{{- define "features.lokiLogsReceiver.destinations" }}
{{- if .Values.lokiLogsReceiver.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.lokiLogsReceiver.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.lokiLogsReceiver.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.lokiLogsReceiver.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.lokiLogsReceiver.collector.values" }}
{{- if .Values.lokiLogsReceiver.enabled -}}
  {{- $values := dict }}
  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" "lokiLogsReceiver") }}
  {{- $collectorValues := (include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml) }}
  {{- $extraPorts := deepCopy (dig "alloy" "extraPorts" list $collectorValues) }}
  {{- if eq (include "collectors.hasExtraPort" (dict "collectorValues" $collectorValues "portNumber" $.Values.lokiLogsReceiver.port)) "false" }}
    {{- $extraPorts = append $extraPorts (dict "name" "loki-logs" "port" $.Values.lokiLogsReceiver.port "targetPort" $.Values.lokiLogsReceiver.port "protocol" "TCP") }}
  {{- end -}}
  {{- $values = $values | merge (dict "collectors" (dict $collectorName (dict "alloy" (dict "extraPorts" $extraPorts)))) }}
{{- $values | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.lokiLogsReceiver.validate" }}
{{- if .Values.lokiLogsReceiver.enabled -}}
  {{- $featureKey := "lokiLogsReceiver" }}
  {{- $featureName := "Loki Logs Receiver" }}

  {{/* Destination validations */}}
  {{- $destinations := include "features.lokiLogsReceiver.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "featureName" $featureName "Values" $.Values "featureKey" $featureKey) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "lokiLogsReceiver" "featureName" $featureName "type" "logs" "ecosystem" "loki") }}

  {{/* Collector validations */}}
  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
  {{- $collectorValues := (include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml) }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
  {{- include "collectors.requireExtraPort" (dict "collectorValues" $collectorValues "featureName" $featureName "portNumber" $.Values.lokiLogsReceiver.port "portName" "loki-logs" "portProtocol" "TCP") }}
{{- end -}}
{{- end -}}
