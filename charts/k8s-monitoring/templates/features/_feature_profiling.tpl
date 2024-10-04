{{- define "features.profiling.enabled" }}{{ .Values.profiling.enabled }}{{- end }}
{{- define "features.profiling.include" }}
{{- if .Values.profiling.enabled -}}
{{- $destinations := include "features.profiling.destinations" . | fromYamlArray }}
// Feature: Profiling
{{- include "feature.profiling.module" (dict "Values" $.Values.profiling "Files" $.Subcharts.profiling.Files) }}
profiling "feature" {
  profiles_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "profiles" "ecosystem" "pyroscope") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.profiling.destinations" }}
{{- if .Values.profiling.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "profiles" "ecosystem" "pyroscope" "filter" $.Values.profiling.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.profiling.validate" }}
{{- if .Values.profiling.enabled -}}
{{- $featureName := "Profiling" }}
{{- $destinations := include "features.profiling.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "profiles" "ecosystem" "pyroscope" "feature" $featureName) }}
{{- include "collectors.require_collector" (dict "Values" $.Values "name" "alloy-profiles" "feature" $featureName) }}
{{- end -}}
{{- end -}}
