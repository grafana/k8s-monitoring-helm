{{- define "features.hostMetrics.enabled" }}{{ .Values.hostMetrics.enabled }}{{- end }}

{{- define "features.hostMetrics.collectors" }}
{{- if .Values.hostMetrics.enabled -}}
- {{ .Values.hostMetrics.collector }}
{{- end }}
{{- end }}

{{- define "features.hostMetrics.include" }}
{{- if .Values.hostMetrics.enabled -}}
{{- $destinations := include "features.hostMetrics.destinations" . | fromYamlArray }}
// Feature: Host Metrics
{{- include "feature.hostMetrics.module" (dict "Values" $.Values.hostMetrics "Files" $.Subcharts.hostMetrics.Files "Release" $.Release "telemetryServices" $.Values.telemetryServices) }}
host_metrics "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics.destinations" }}
{{- if .Values.hostMetrics.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.hostMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.hostMetrics.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.hostMetrics.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.hostMetrics.collector.values" }}{{- end -}}

{{- define "features.hostMetrics.validate" }}
{{- if .Values.hostMetrics.enabled }}
  {{- $featureName := "Kubernetes Host metrics" }}
  {{- $destinations := include "features.hostMetrics.destinations" . | fromYamlArray }}
  {{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}

  {{- range $collector := include "features.hostMetrics.collectors" . | fromYamlArray }}
    {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
  {{- end }}

  {{- include "feature.hostMetrics.validate" (dict "Values" $.Values.hostMetrics "telemetryServices" $.Values.telemetryServices) }}
{{- end }}
{{- end }}
