{{- define "features.podLogsViaKubernetesApi.enabled" }}{{ .Values.podLogsViaKubernetesApi.enabled }}{{- end }}

{{- define "features.podLogsViaKubernetesApi.collectors" }}
{{- if .Values.podLogsViaKubernetesApi.enabled -}}
- {{ .Values.podLogsViaKubernetesApi.collector }}
{{- end }}
{{- end }}

{{- define "features.podLogsViaKubernetesApi.include" }}
{{- if .Values.podLogsViaKubernetesApi.enabled -}}
{{- $destinations := include "features.podLogsViaKubernetesApi.destinations" . | fromYamlArray }}

// Feature: Pod Logs via Kubernetes API
{{- include "feature.podLogsViaKubernetesApi.module" (dict "Values" .Values.podLogsViaKubernetesApi "Files" $.Subcharts.podLogsViaKubernetesApi.Files) }}
pod_logs_via_kubernetes_api "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.podLogsViaKubernetesApi.destinations" }}
{{- if .Values.podLogsViaKubernetesApi.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.podLogsViaKubernetesApi.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.podLogsViaKubernetesApi.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.podLogsViaKubernetesApi.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.podLogsViaKubernetesApi.collector.values" }}{{- end -}}

{{- define "features.podLogsViaKubernetesApi.validate" }}
{{- if .Values.podLogsViaKubernetesApi.enabled -}}
{{- $featureName := "Kubernetes Pod logs via Kubernetes API" }}
{{- $destinations := include "features.podLogsViaKubernetesApi.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "logs" "ecosystem" "loki" "feature" $featureName) }}

{{- range $collectorName := include "features.podLogsViaKubernetesApi.collectors" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (deepCopy $ | merge (dict "collectorName" $collectorName)) | fromYaml }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collectorName "feature" $featureName) }}
  {{- include "feature.podLogsViaKubernetesApi.collector.validate" (dict "Values" $.Values.podLogsViaKubernetesApi "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}
{{- end -}}
{{- end -}}
