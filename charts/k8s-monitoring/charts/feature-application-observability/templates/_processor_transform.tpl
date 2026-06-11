{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.transform/ */}}

{{/* Service attribute fallback: fill missing/empty service.name and service.namespace from Kubernetes
     metadata extracted by the k8sattributes processor. Reads the app.kubernetes.io/name pod label via the
     internal k8s.grafana.com/internal.app-name attribute (see _processor_k8sattributes.tpl), which is
     removed again by the cleanup helper after user transforms have run. */}}
{{- define "feature.applicationObservability.processor.transform.serviceFallbackStatements" -}}
`set(attributes["service.name"], attributes["k8s.grafana.com/internal.app-name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.grafana.com/internal.app-name"] != nil and attributes["k8s.grafana.com/internal.app-name"] != ""`,
`set(attributes["service.name"], attributes["k8s.deployment.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.deployment.name"] != nil and attributes["k8s.deployment.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.statefulset.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.statefulset.name"] != nil and attributes["k8s.statefulset.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.daemonset.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.daemonset.name"] != nil and attributes["k8s.daemonset.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.cronjob.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.cronjob.name"] != nil and attributes["k8s.cronjob.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.job.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.job.name"] != nil and attributes["k8s.job.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.pod.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.pod.name"] != nil and attributes["k8s.pod.name"] != ""`,
`set(attributes["service.namespace"], attributes["k8s.namespace.name"]) where (attributes["service.namespace"] == nil or attributes["service.namespace"] == "") and attributes["k8s.namespace.name"] != nil and attributes["k8s.namespace.name"] != ""`,
{{- end }}
{{- define "feature.applicationObservability.processor.transform.serviceFallbackCleanup" -}}
`delete_key(attributes, "k8s.grafana.com/internal.app-name")`,
{{- end }}

{{- define "feature.applicationObservability.processor.transform.alloy.target" }}otelcol.processor.transform.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.transform.alloy" }}
otelcol.processor.transform "{{ .name | default "default" }}" {
  error_mode = {{ .Values.processors.transform.errorMode | quote }}

{{- if .Values.metrics.enabled }}
{{- if or .Values.processors.transform.setServiceAttributesFromKubernetes .Values.metrics.transforms.resource }}
  metric_statements {
    context = "resource"
    statements = [
{{- if .Values.processors.transform.setServiceAttributesFromKubernetes }}
{{ include "feature.applicationObservability.processor.transform.serviceFallbackStatements" . | trim | indent 6 }}
{{- end }}
{{- range $transform := .Values.metrics.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- if .Values.processors.transform.setServiceAttributesFromKubernetes }}
{{ include "feature.applicationObservability.processor.transform.serviceFallbackCleanup" . | trim | indent 6 }}
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
{{- if .Values.processors.transform.setServiceAttributesFromKubernetes }}
{{ include "feature.applicationObservability.processor.transform.serviceFallbackStatements" . | trim | indent 6 }}
{{- end }}
{{- if .Values.logs.transforms.resource }}
{{- range $transform := .Values.logs.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- end }}
      "set(attributes[\"pod\"], attributes[\"k8s.pod.name\"])",
      "set(attributes[\"namespace\"], attributes[\"k8s.namespace.name\"])",
      "set(attributes[\"loki.resource.labels\"], \"{{ .Values.logs.transforms.labels | join ", " }}\")",
{{- if .Values.processors.transform.setServiceAttributesFromKubernetes }}
{{ include "feature.applicationObservability.processor.transform.serviceFallbackCleanup" . | trim | indent 6 }}
{{- end }}
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
{{- if or .Values.processors.transform.setServiceAttributesFromKubernetes .Values.traces.transforms.resource }}
  trace_statements {
    context = "resource"
    statements = [
{{- if .Values.processors.transform.setServiceAttributesFromKubernetes }}
{{ include "feature.applicationObservability.processor.transform.serviceFallbackStatements" . | trim | indent 6 }}
{{- end }}
{{- range $transform := .Values.traces.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- if .Values.processors.transform.setServiceAttributesFromKubernetes }}
{{ include "feature.applicationObservability.processor.transform.serviceFallbackCleanup" . | trim | indent 6 }}
{{- end }}
    ]
  }
{{- end }}
{{- if or .Values.traces.transforms.span .Values.traces.setSpanNameSemanticConvention }}
  trace_statements {
    context = "span"
    statements = [
{{- range $transform := .Values.traces.transforms.span }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- if .Values.traces.setSpanNameSemanticConvention }}
     "set_semconv_span_name(\"{{ .Values.traces.setSpanNameSemanticConvention }}\", \"original_span_name\")",
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
