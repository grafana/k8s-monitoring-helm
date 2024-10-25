{{- define "features.clusterMetrics.enabled" }}{{ .Values.clusterMetrics.enabled }}{{- end }}

{{- define "features.clusterMetrics.collectors" }}
{{- if .Values.clusterMetrics.enabled -}}
- {{ .Values.clusterMetrics.collector }}
{{- end }}
{{- end }}

{{- define "features.clusterMetrics.include" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray }}
// Feature: Cluster Metrics
{{- include "feature.clusterMetrics.module" (dict "Values" $.Values.clusterMetrics "Files" $.Subcharts.clusterMetrics.Files "Release" $.Release) }}
cluster_metrics "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.clusterMetrics.destinations" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.clusterMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.clusterMetrics.validate" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- $featureName := "Kubernetes Cluster metrics" }}
{{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
{{- range $collector := include "features.clusterMetrics.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
{{- end -}}
{{- end -}}
{{- end -}}
