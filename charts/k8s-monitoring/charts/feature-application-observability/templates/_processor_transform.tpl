{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.transform/ */}}
{{- define "feature.applicationObservability.processor.transform.alloy.target" }}otelcol.processor.transform.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.transform.alloy" }}
otelcol.processor.transform "{{ .name | default "default" }}" {
  error_mode = "ignore"

{{- if .Values.metrics.enabled }}
{{- if .Values.metrics.transforms.resource }}
  metric_statements {
    context = "resource"
    statements = [
{{- range $transform := .Values.metrics.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if .Values.metrics.transforms.metric }}
  metric_statements {
    context = "metric"
    statements = [
{{- range $transform := .Values.metrics.transforms.metric }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if .Values.metrics.transforms.datapoint }}
  metric_statements {
    context = "datapoint"
    statements = [
{{- range $transform := .Values.metrics.transforms.datapoint }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- end }}
{{- if .Values.logs.enabled }}
  log_statements {
    context = "resource"
    statements = [
{{- if .Values.logs.transforms.resource }}
{{- range $transform := .Values.logs.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- end }}
      "set(attributes[\"pod\"], attributes[\"k8s.pod.name\"])",
      "set(attributes[\"namespace\"], attributes[\"k8s.namespace.name\"])",
      "set(attributes[\"loki.resource.labels\"], \"{{ .Values.logs.transforms.labels | join ", " }}\")",
    ]
  }
{{- if .Values.logs.transforms.log }}
  log_statements {
    context = "log"
    statements = [
{{- range $transform := .Values.logs.transforms.log }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- end }}
{{- if .Values.traces.enabled }}
{{- if .Values.traces.transforms.resource }}
  trace_statements {
    context = "resource"
    statements = [
{{- range $transform := .Values.traces.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if .Values.traces.transforms.span }}
  trace_statements {
    context = "span"
    statements = [
{{- range $transform := .Values.traces.transforms.span }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if .Values.traces.transforms.spanevent }}
  trace_statements {
    context = "spanevent"
    statements = [
{{- range $transform := .Values.traces.transforms.spanevent }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- end }}

  output {
{{- if and .metrics .Values.metrics.enabled }}
    metrics = {{ .metrics }}
{{- end }}
{{- if and .logs .Values.logs.enabled }}
    logs = {{ .logs }}
{{- end }}
{{- if and .traces .Values.traces.enabled }}
    traces = {{ .traces }}
{{- end }}
  }
}
{{- end }}