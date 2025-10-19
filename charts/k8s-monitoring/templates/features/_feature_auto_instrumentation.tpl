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

{{- define "features.autoInstrumentation.validate" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- $featureName := "Auto-Instrumentation" }}
{{- $destinations := include "features.autoInstrumentation.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
{{- range $collector := include "features.autoInstrumentation.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
{{- end -}}

{{/* Check if Application Observability is needed for traces */}}
{{- if and (not .Values.applicationObservability.enabled) (not .Values.autoInstrumentation.spanMetricsOnly) }}
  {{- $hasTraceDestinations := false }}
  {{- range $destination := .Values.destinations }}
    {{- if and $destination.traces (dig "enabled" false $destination.traces) }}
      {{- $hasTraceDestinations = true }}
    {{- end }}
  {{- end }}
  {{- $msg := list "" "Auto-Instrumentation is enabled but Application Observability is not enabled." }}
  {{- $msg = append $msg "Auto-instrumentation with Beyla can generate traces, but they will not be sent anywhere without receivers." }}
  {{- if $hasTraceDestinations }}
    {{- $msg = append $msg "You have trace-capable destinations configured but no receivers to accept traces from Beyla." }}
  {{- else }}
    {{- $msg = append $msg "You have no trace destinations configured, so traces will not be collected." }}
  {{- end }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "To enable trace collection, add both a trace destination and Application Observability:" }}
  {{- $msg = append $msg "" }}
  {{- if not $hasTraceDestinations }}
    {{- $msg = append $msg "destinations:" }}
    {{- $msg = append $msg "  - name: grafana-cloud-traces" }}
    {{- $msg = append $msg "    type: otlp" }}
    {{- $msg = append $msg "    url: https://tempo-prod-example.grafana.net" }}
    {{- $msg = append $msg "    metrics: {enabled: false}" }}
    {{- $msg = append $msg "    logs: {enabled: false}" }}
    {{- $msg = append $msg "    traces: {enabled: true}" }}
    {{- $msg = append $msg "" }}
  {{- end }}
  {{- $msg = append $msg "applicationObservability:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- $msg = append $msg "  receivers:" }}
  {{- $msg = append $msg "    otlp:" }}
  {{- $msg = append $msg "      grpc:" }}
  {{- $msg = append $msg "        enabled: true" }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "OR, if you only want span metrics from auto-instrumentation (no full traces), set:" }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "autoInstrumentation:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- $msg = append $msg "  spanMetricsOnly: true" }}
  {{- fail (join "\n" $msg) }}
{{- end -}}
{{- end -}}
{{- end -}}
