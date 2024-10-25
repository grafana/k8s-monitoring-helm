{{- define "features.autoInstrumentation.enabled" }}{{ .Values.autoInstrumentation.enabled }}{{- end }}

{{- define "features.autoInstrumentation.collectors" }}
{{- if .Values.autoInstrumentation.enabled -}}
- {{ .Values.autoInstrumentation.collector }}
{{- end }}
{{- end }}

{{- define "features.autoInstrumentation.include" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- $destinations := include "features.autoInstrumentation.destinations" . | fromYamlArray }}
// Feature: Auto-Instrumentation
{{- include "feature.autoInstrumentation.module" (dict "Values" $.Values.autoInstrumentation "Files" $.Subcharts.autoInstrumentation.Files) }}
auto_instrumentation "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.autoInstrumentation.destinations" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.autoInstrumentation.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.autoInstrumentation.validate" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- $featureName := "Auto-Instrumentation" }}
{{- $destinations := include "features.autoInstrumentation.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
{{- range $collector := include "features.autoInstrumentation.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
{{- end -}}
{{- end -}}
{{- end -}}
