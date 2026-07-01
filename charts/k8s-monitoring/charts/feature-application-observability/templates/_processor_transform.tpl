{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.transform/ */}}
{{- define "feature.applicationObservability.processor.transform.alloy.target" }}otelcol.processor.transform.{{ .name | default "default" }}.input{{ end }}
{{/*
Fallback statements to detect service.name and service.namespace when not set by the application or by the
resource.opentelemetry.io/* pod annotations (extracted by the k8sattributes processor). Follows the OTel Operator
service name semantic conventions: instance label, name label, workload owner name, pod name.
*/}}
{{- define "feature.applicationObservability.processor.transform.serviceDetectionStatements" }}
// Set service.name by choosing the first value found from the following ordered list:
// - service.name as reported by the application or set from the resource.opentelemetry.io/service.name annotation
// - pod.label[app.kubernetes.io/instance]
// - pod.label[app.kubernetes.io/name]
// - k8s.workload.name (Deployment, StatefulSet, DaemonSet, CronJob, Job, ...)
// - k8s.pod.name
`set(attributes["service.name"], attributes["app.kubernetes.io/instance"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["app.kubernetes.io/instance"] != nil and attributes["app.kubernetes.io/instance"] != ""`,
`set(attributes["service.name"], attributes["app.kubernetes.io/name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["app.kubernetes.io/name"] != nil and attributes["app.kubernetes.io/name"] != ""`,
`set(attributes["service.name"], attributes["k8s.deployment.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.deployment.name"] != nil and attributes["k8s.deployment.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.replicaset.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.replicaset.name"] != nil and attributes["k8s.replicaset.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.statefulset.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.statefulset.name"] != nil and attributes["k8s.statefulset.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.daemonset.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.daemonset.name"] != nil and attributes["k8s.daemonset.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.cronjob.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.cronjob.name"] != nil and attributes["k8s.cronjob.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.job.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.job.name"] != nil and attributes["k8s.job.name"] != ""`,
`set(attributes["service.name"], attributes["k8s.pod.name"]) where (attributes["service.name"] == nil or attributes["service.name"] == "") and attributes["k8s.pod.name"] != nil and attributes["k8s.pod.name"] != ""`,

// Set service.namespace to the pod namespace if not already set
`set(attributes["service.namespace"], attributes["k8s.namespace.name"]) where (attributes["service.namespace"] == nil or attributes["service.namespace"] == "") and attributes["k8s.namespace.name"] != nil and attributes["k8s.namespace.name"] != ""`,

// Remove the temporary pod label attributes used for service.name detection
`delete_key(attributes, "app.kubernetes.io/instance")`,
`delete_key(attributes, "app.kubernetes.io/name")`,
{{- end }}
{{- define "feature.applicationObservability.processor.transform.alloy" }}
otelcol.processor.transform "{{ .name | default "default" }}" {
  error_mode = {{ .Values.processors.transform.errorMode | quote }}

{{- if .Values.metrics.enabled }}
{{- if or .Values.metrics.transforms.resource .Values.alignServiceNameWithOTelOperator }}
  metric_statements {
    context = "resource"
    statements = [
{{- range $transform := .Values.metrics.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- if .Values.alignServiceNameWithOTelOperator }}
{{- include "feature.applicationObservability.processor.transform.serviceDetectionStatements" . | indent 6 }}
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
{{- if .Values.alignServiceNameWithOTelOperator }}
{{- include "feature.applicationObservability.processor.transform.serviceDetectionStatements" . | indent 6 }}
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
{{- if or .Values.traces.transforms.resource .Values.alignServiceNameWithOTelOperator }}
  trace_statements {
    context = "resource"
    statements = [
{{- range $transform := .Values.traces.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- if .Values.alignServiceNameWithOTelOperator }}
{{- include "feature.applicationObservability.processor.transform.serviceDetectionStatements" . | indent 6 }}
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
