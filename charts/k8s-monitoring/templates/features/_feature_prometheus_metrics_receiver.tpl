{{- define "features.prometheusMetricsReceiver.enabled" }}{{ .Values.prometheusMetricsReceiver.enabled }}{{- end }}

{{- define "features.prometheusMetricsReceiver.include" }}
{{- if .Values.prometheusMetricsReceiver.enabled -}}
{{- $destinations := include "features.prometheusMetricsReceiver.destinations" . | fromYamlArray }}
// Feature: Prometheus Metrics Receiver
{{- include "feature.prometheusMetricsReceiver.module" (dict "Values" $.Values.prometheusMetricsReceiver "Files" $.Subcharts.prometheusMetricsReceiver.Files) }}
prometheus_metrics_receiver "feature" {
  metrics_destinations = [
    {{ include "dataProcessors.pipeline.targets.forFeature" (dict "root" $ "featureKey" "prometheusMetricsReceiver" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- include "dataProcessors.pipeline.render.forFeature" (dict "root" $ "featureKey" "prometheusMetricsReceiver" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end -}}
{{- end -}}

{{- define "features.prometheusMetricsReceiver.destinations" }}
{{- if .Values.prometheusMetricsReceiver.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.prometheusMetricsReceiver.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.prometheusMetricsReceiver.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.prometheusMetricsReceiver.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.prometheusMetricsReceiver.collector.values" }}
{{- if .Values.prometheusMetricsReceiver.enabled -}}
  {{- $values := dict }}
  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" "prometheusMetricsReceiver") }}
  {{- $collectorValues := (include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml) }}
  {{- $extraPorts := deepCopy (dig "alloy" "extraPorts" list $collectorValues) }}
  {{- if eq (include "collectors.hasExtraPort" (dict "collectorValues" $collectorValues "portNumber" $.Values.prometheusMetricsReceiver.port)) "false" }}
    {{- $extraPorts = append $extraPorts (dict "name" "metrics" "port" $.Values.prometheusMetricsReceiver.port "targetPort" $.Values.prometheusMetricsReceiver.port "protocol" "TCP") }}
  {{- end -}}
  {{- $values = $values | merge (dict "collectors" (dict $collectorName (dict "alloy" (dict "extraPorts" $extraPorts)))) }}
{{- $values | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.prometheusMetricsReceiver.validate" }}
{{- if .Values.prometheusMetricsReceiver.enabled -}}
  {{- $featureKey := "prometheusMetricsReceiver" }}
  {{- $featureName := "Prometheus Metrics Receiver" }}

  {{/* Destination validations */}}
  {{- $destinations := include "features.prometheusMetricsReceiver.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName "Values" $.Values "featureKey" $featureKey) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "prometheusMetricsReceiver" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}

  {{/* Collector validations */}}
  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
  {{- $collectorValues := (include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml) }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
  {{- include "collectors.requireExtraPort" (dict "collectorName" $collectorName "collectorValues" $collectorValues "featureName" $featureName "portNumber" $.Values.prometheusMetricsReceiver.port "portName" "metrics" "portProtocol" "TCP") }}
{{- end -}}
{{- end -}}
