{{- define "features.profiling.enabled" }}{{ .Values.profiling.enabled }}{{- end }}

{{- define "features.profiling.include" }}
{{- if .Values.profiling.enabled -}}
{{- $destinations := include "features.profiling.destinations" . | fromYamlArray }}
// Feature: Profiling
{{- include "feature.profiling.module" (dict "Values" $.Values.profiling "Files" $.Subcharts.profiling.Files) }}
profiling "feature" {
  profiles_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "profiles" "ecosystem" "pyroscope") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.profiling.destinations" }}
{{- if .Values.profiling.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "profiles" "ecosystem" "pyroscope" "filter" $.Values.profiling.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.profiling.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.profiling.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "pyroscope" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.profiling.collector.values" }}{{- end -}}

{{- define "features.profiling.chooseCollector" -}}{{- end -}}

{{- define "features.profiling.validate" }}
{{- if .Values.profiling.enabled -}}
{{- $featureKey := "profiling" }}
{{- $featureName := "Profiling" }}
{{- $destinations := include "features.profiling.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "profiles" "ecosystem" "pyroscope" "featureName" $featureName) }}
{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- end -}}
{{- end -}}
