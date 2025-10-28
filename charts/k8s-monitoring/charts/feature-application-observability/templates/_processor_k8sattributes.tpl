{{- define "feature.applicationObservability.processor.k8sattributes.hasFilter" }}
  {{- if .Values.processors.k8sattributes.filters.byNode }}true
  {{- else if .Values.processors.k8sattributes.filters.ownNode }}true
  {{- else if .Values.processors.k8sattributes.filters.byNamespace }}true
  {{- else if .Values.processors.k8sattributes.filters.byLabel }}true
  {{- else if .Values.processors.k8sattributes.filters.byField }}true
  {{- else }}false
  {{- end }}
{{- end }}

{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.k8sattributes/ */}}
{{- define "feature.applicationObservability.processor.k8sattributes.alloy.target" }}otelcol.processor.k8sattributes.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.k8sattributes.alloy" }}
otelcol.processor.k8sattributes "{{ .name | default "default" }}" {
  passthrough = {{ .Values.processors.k8sattributes.passthrough }}
  {{- if eq (include "feature.applicationObservability.processor.k8sattributes.hasFilter" . | trim) "true" }}
  filter {
    {{- if .Values.processors.k8sattributes.filters.byNode }}
    node = {{ .Values.processors.k8sattributes.filters.byNode | quote }}
    {{- else if .Values.processors.k8sattributes.filters.ownNode }}
    node = sys.env("HOSTNAME")
    {{- end }}
    {{- if .Values.processors.k8sattributes.filters.byNamespace }}
    namespace = {{ .Values.processors.k8sattributes.filters.byNamespace | quote }}
    {{- end }}
    {{- if .Values.processors.k8sattributes.filters.byLabel }}
    label {
    {{- range $labelFilter := .Values.processors.k8sattributes.filters.byLabel }}
      key = {{ $labelFilter.key | quote }}
      value = {{ $labelFilter.value | quote }}
      {{- if $labelFilter.op }}
      op = {{ $labelFilter.op | quote }}
      {{- end }}
    {{- end }}
    }
    {{- end }}
    {{- if .Values.processors.k8sattributes.filters.byField }}
    {{- range $fieldFilter := .Values.processors.k8sattributes.filters.byField }}
    field {
      key = {{ $fieldFilter.key | quote }}
      value = {{ $fieldFilter.value | quote }}
      {{- if $fieldFilter.op }}
      op = {{ $fieldFilter.op | quote }}
      {{- end }}
    }
    {{- end }}
    {{- end }}
  }
  {{- end }}
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
