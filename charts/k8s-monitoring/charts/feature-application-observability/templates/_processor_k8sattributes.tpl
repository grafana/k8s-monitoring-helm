{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.k8sattributes/ */}}
{{- define "feature.applicationObservability.processor.k8sattributes.alloy.target" }}otelcol.processor.k8sattributes.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.k8sattributes.alloy" }}
otelcol.processor.k8sattributes "{{ .name | default "default" }}" {
  passthrough = {{ .Values.processors.k8sattributes.passthrough }}
  extract {
{{- if .Values.processors.k8sattributes.metadata }}
    metadata = {{ .Values.processors.k8sattributes.metadata | toJson }}
{{- end }}
{{- range .Values.processors.k8sattributes.labels }}
    label {
    {{- range $k, $v := . }}
      {{ $k }} = {{ $v | quote }}
    {{- end }}
    }
{{- end }}
{{- range .Values.processors.k8sattributes.annotations }}
    annotation {
    {{- range $k, $v := . }}
      {{ $k }} = {{ $v | quote }}
    {{- end }}
    }
{{- end }}
  }
  {{- range .Values.processors.k8sattributes.podAssociation }}
  pod_association {
    source {
      from = "{{ .from }}"
    {{- if .name }}
      name = "{{ .name }}"
    {{- end }}
    }
  }
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
