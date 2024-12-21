{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.filter/ */}}
{{- define "feature.applicationObservability.processor.filter.enabled" }}
{{- if and .Values.metrics.enabled (or .Values.metrics.filters.metric .Values.metrics.filters.datapoint) -}}
true
{{- else if and .Values.logs.enabled .Values.logs.filters.log_record -}}
true
{{- else if and .Values.traces.enabled (or .Values.traces.filters.span .Values.traces.filters.spanevent) -}}
true
{{- else -}}
false
{{- end }}
{{- end }}
{{- define "feature.applicationObservability.processor.filter.alloy.target" }}otelcol.processor.filter.{{ .name | default "default" }}.target{{ end }}
{{- define "feature.applicationObservability.processor.filter.alloy" }}
otelcol.processor.filter "{{ .name | default "default" }}" {
{{- if and .Values.metrics.enabled (or .Values.metrics.filters.metric .Values.metrics.filters.datapoint) }}
  metrics {
{{- if .Values.metrics.filters.metric }}
    metric = [
{{- range $filter := .Values.metrics.filters.metric }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
{{- end }}
{{- if .Values.metrics.filters.datapoint }}
    datapoint = [
{{- range $filter := .Values.metrics.filters.datapoint }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
{{- end }}
  }
{{- end }}
{{- if and .Values.logs.enabled .Values.logs.filters.log_record }}
  logs {
    log_record = [
{{- range $filter := .Values.logs.filters.log_record }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if and .Values.traces.enabled (or .Values.traces.filters.span .Values.traces.filters.spanevent) }}
  traces {
{{- if .Values.traces.filters.span }}
    span = [
{{- range $filter := .Values.traces.filters.span }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
{{- end }}
{{- if .Values.traces.filters.spanevent }}
    spanevent = [
{{- range $filter := .Values.traces.filters.spanevent }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
{{- end }}
  }
{{- end }}
  output {
{{- if and .metricsOutput .Values.metrics.enabled }}
    metrics = {{ .metricsOutput }}
{{- end }}
{{- if and .logsOutput .Values.logs.enabled }}
    logs = {{ .logsOutput }}
{{- end }}
{{- if and .tracesOutput .Values.traces.enabled }}
    traces = {{ .tracesOutput }}
{{- end }}
  }
}
{{- end }}