{{- define "features.prometheusOperatorObjects.enabled" }}{{ .Values.prometheusOperatorObjects.enabled }}{{- end }}

{{- define "features.prometheusOperatorObjects.collectors" }}
{{- if .Values.prometheusOperatorObjects.enabled -}}
- {{ .Values.prometheusOperatorObjects.collector }}
{{- end }}
{{- end }}

{{- define "features.prometheusOperatorObjects.include" }}
{{- if .Values.prometheusOperatorObjects.enabled -}}
{{- $destinations := include "features.prometheusOperatorObjects.destinations" . | fromYamlArray }}
// Feature: Prometheus Operator Objects
{{- include "feature.prometheusOperatorObjects.module" (dict "Values" $.Values.prometheusOperatorObjects "Files" $.Subcharts.prometheusOperatorObjects.Files) }}
prometheus_operator_objects "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.prometheusOperatorObjects.destinations" }}
{{- if .Values.prometheusOperatorObjects.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.prometheusOperatorObjects.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.prometheusOperatorObjects.validate" }}
{{- if .Values.prometheusOperatorObjects.enabled -}}
{{- $featureName := "Prometheus Operator Objects" }}
{{- $destinations := include "features.prometheusOperatorObjects.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
{{- range $collector := include "features.prometheusOperatorObjects.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
{{- end -}}
{{- include "feature.prometheusOperatorObjects.validate" (dict "Values" $.Values.prometheusOperatorObjects) }}
{{- end -}}
{{- end -}}
