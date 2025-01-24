{{/* Inputs: Values (values) metricsOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.connector.spanlogs/ */}}
{{- define "feature.applicationObservability.connector.spanlogs.alloy.target" }}otelcol.connector.spanlogs.{{ .name | default "default" }}.input{{- end }}
{{- define "feature.applicationObservability.connector.spanlogs.alloy" }}
otelcol.connector.spanlogs "{{ .name | default "default" }}" {
{{- if .Values.connectors.spanLogs.spans }}
  spans = true
{{- end }}
{{- if .Values.connectors.spanLogs.spansAttributes }}
  spans_attributes = {{ .Values.connectors.spanLogs.spansAttributes | toJson }}
{{- end }}
{{- if .Values.connectors.spanLogs.roots }}
  roots = true
{{- end }}
{{- if .Values.connectors.spanLogs.process }}
  process = true
{{- end }}
{{- if .Values.connectors.spanLogs.processAttributes }}
  process_attributes = {{ .Values.connectors.spanLogs.processAttributes | toJson }}
{{- end }}
{{- if .Values.connectors.spanLogs.labels }}
  labels = {{ .Values.connectors.spanLogs.labels | toJson }}
{{- end }}

  output {
{{- if and .logs .Values.logs.enabled }}
    logs = {{ .logs }}
{{- end }}
  }
}
{{- end }}