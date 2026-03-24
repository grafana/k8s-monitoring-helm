{{- define "features.podLogsViaOpenTelemetry.enabled" }}{{ .Values.podLogsViaOpenTelemetry.enabled }}{{- end }}

{{- define "features.podLogsViaOpenTelemetry.include" }}
{{- if .Values.podLogsViaOpenTelemetry.enabled -}}
{{- $destinations := include "features.podLogsViaOpenTelemetry.destinations" . | fromYamlArray }}

// Feature: Pod Logs (OpenTelemetry)
{{- include "feature.podLogsViaOpenTelemetry.module" (dict "Values" .Values.podLogsViaOpenTelemetry "Files" $.Subcharts.podLogsViaOpenTelemetry.Files) }}
pod_logs_via_opentelemetry "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "logs" "ecosystem" "otlp") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.podLogsViaOpenTelemetry.destinations" }}
{{- if .Values.podLogsViaOpenTelemetry.enabled -}}
  {{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "otlp" "filter" $.Values.podLogsViaOpenTelemetry.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.podLogsViaOpenTelemetry.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.podLogsViaOpenTelemetry.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "otlp" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.podLogsViaOpenTelemetry.collector.values" }}{{- end -}}

{{- define "features.podLogsViaOpenTelemetry.chooseCollector" -}}{{- end -}}

{{- define "features.podLogsViaOpenTelemetry.validate" }}
{{- if .Values.podLogsViaOpenTelemetry.enabled -}}
{{- $featureKey := "podLogsViaOpenTelemetry" }}
{{- $featureName := "Kubernetes Pod logs via OpenTelemetry" }}
{{- $destinations := include "features.podLogsViaOpenTelemetry.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "logs" "ecosystem" "otlp" "featureName" $featureName) }}

{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
{{- include "feature.podLogsViaOpenTelemetry.collector.validate" (dict "Values" $.Values.podLogsViaOpenTelemetry "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}
{{- end -}}
