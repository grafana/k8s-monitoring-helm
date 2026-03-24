{{- define "features.prometheusOperatorObjects.enabled" }}{{ .Values.prometheusOperatorObjects.enabled }}{{- end }}

{{- define "features.prometheusOperatorObjects.include" }}
{{- if .Values.prometheusOperatorObjects.enabled -}}
{{- $destinations := include "features.prometheusOperatorObjects.destinations" . | fromYamlArray }}
// Feature: Prometheus Operator Objects
{{- include "feature.prometheusOperatorObjects.module" (dict "Values" $.Values.prometheusOperatorObjects "Files" $.Subcharts.prometheusOperatorObjects.Files) }}
prometheus_operator_objects "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.prometheusOperatorObjects.destinations" }}
{{- if .Values.prometheusOperatorObjects.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.prometheusOperatorObjects.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.prometheusOperatorObjects.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.prometheusOperatorObjects.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.prometheusOperatorObjects.collector.values" }}{{- end -}}

{{- define "features.prometheusOperatorObjects.chooseCollector" -}}{{- end -}}

{{- define "features.prometheusOperatorObjects.validate" }}
{{- if .Values.prometheusOperatorObjects.enabled -}}
{{- $featureKey := "prometheusOperatorObjects" }}
{{- $featureName := "Prometheus Operator Objects" }}
{{- $destinations := include "features.prometheusOperatorObjects.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName) }}
{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- include "feature.prometheusOperatorObjects.validate" (dict "Values" $.Values.prometheusOperatorObjects) }}
{{- end -}}
{{- end -}}
