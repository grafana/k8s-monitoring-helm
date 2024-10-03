{{- define "features.clusterEvents.enabled" }}{{ .Values.clusterEvents.enabled }}{{- end }}
{{- define "features.clusterEvents.include" }}
{{- if .Values.clusterEvents.enabled -}}
{{- $destinations := include "features.clusterEvents.destinations" . | fromYamlArray }}
// Feature: Cluster Events
{{- include "feature.clusterEvents.module" (dict "Values" $.Values.clusterEvents "Files" $.Subcharts.clusterEvents.Files) }}
cluster_events "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.clusterEvents.destinations" }}
{{- if .Values.clusterEvents.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.clusterEvents.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.clusterEvents.validate" }}
{{- if .Values.clusterEvents.enabled -}}
{{- $featureName := "Kubernetes Cluster events" }}
{{- $destinations := include "features.clusterEvents.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "feature" $featureName) }}
{{- include "collectors.require_collector" (dict "Values" $.Values "name" "alloy-singleton" "feature" $featureName) }}
{{- end -}}
{{- end -}}
