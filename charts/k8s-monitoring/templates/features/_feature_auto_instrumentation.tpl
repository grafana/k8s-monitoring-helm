{{- define "features.autoInstrumentation.enabled" }}{{ .Values.autoInstrumentation.enabled }}{{- end }}

{{- define "features.autoInstrumentation.include" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- $destinations := include "features.autoInstrumentation.destinations" . | fromYamlArray }}
// Feature: Auto-Instrumentation
{{- include "feature.autoInstrumentation.module" (dict "Values" $.Values.autoInstrumentation "Files" $.Subcharts.autoInstrumentation.Files) }}
auto_instrumentation "feature" {
  metrics_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "autoInstrumentation" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "autoInstrumentation" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end -}}
{{- end -}}

{{- define "features.autoInstrumentation.validate" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- $featureKey := "autoInstrumentation" }}
{{- $featureName := "Auto-Instrumentation" }}
{{- $destinations := include "features.autoInstrumentation.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName) }}
{{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "autoInstrumentation" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}
{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- end -}}
{{- end -}}

{{- define "features.autoInstrumentation.destinations" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.autoInstrumentation.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.autoInstrumentation.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.autoInstrumentation.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.autoInstrumentation.collector.values" }}{{- end -}}

{{- define "features.autoInstrumentation.chooseCollector" -}}{{- end -}}
