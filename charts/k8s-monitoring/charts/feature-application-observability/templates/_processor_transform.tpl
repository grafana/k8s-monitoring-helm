{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.transform/ */}}
{{- define "feature.applicationObservability.processor.transform.alloy.target" }}otelcol.processor.transform.{{ .name | default "default" }}.input{{ end }}

{{/*
Fallback statements to detect service.name and service.namespace when not set by the application or by the
resource.opentelemetry.io/* pod annotations (extracted by the k8sattributes processor). Follows the OpenTelemetry
semantic conventions for Kubernetes service names: instance label, name label, workload owner name, pod name.
*/}}
{{- define "feature.applicationObservability.processor.transform.serviceDetectionStatements" }}
// Set service.name by choosing the first value found from the following ordered list:
// - service.name as reported by the application or set from the resource.opentelemetry.io/service.name annotation
// - pod.label[app.kubernetes.io/instance]
// - pod.label[app.kubernetes.io/name]
// - k8s.workload.name (Deployment, StatefulSet, DaemonSet, CronJob, Job, ...)
// - k8s.pod.name
// The instance/name pod labels are read from temporary attributes (k8s_monitoring.tmp.*) extracted by the
// k8sattributes processor, so the cleanup below only ever deletes attributes this feature added.
`set(resource.attributes["service.name"], resource.attributes["k8s_monitoring.tmp.instance"]) where (resource.attributes["service.name"] == nil or resource.attributes["service.name"] == "") and resource.attributes["k8s_monitoring.tmp.instance"] != nil and resource.attributes["k8s_monitoring.tmp.instance"] != ""`,
`set(resource.attributes["service.name"], resource.attributes["k8s_monitoring.tmp.name"]) where (resource.attributes["service.name"] == nil or resource.attributes["service.name"] == "") and resource.attributes["k8s_monitoring.tmp.name"] != nil and resource.attributes["k8s_monitoring.tmp.name"] != ""`,
`set(resource.attributes["service.name"], resource.attributes["k8s.deployment.name"]) where (resource.attributes["service.name"] == nil or resource.attributes["service.name"] == "") and resource.attributes["k8s.deployment.name"] != nil and resource.attributes["k8s.deployment.name"] != ""`,
`set(resource.attributes["service.name"], resource.attributes["k8s.replicaset.name"]) where (resource.attributes["service.name"] == nil or resource.attributes["service.name"] == "") and resource.attributes["k8s.replicaset.name"] != nil and resource.attributes["k8s.replicaset.name"] != ""`,
`set(resource.attributes["service.name"], resource.attributes["k8s.statefulset.name"]) where (resource.attributes["service.name"] == nil or resource.attributes["service.name"] == "") and resource.attributes["k8s.statefulset.name"] != nil and resource.attributes["k8s.statefulset.name"] != ""`,
`set(resource.attributes["service.name"], resource.attributes["k8s.daemonset.name"]) where (resource.attributes["service.name"] == nil or resource.attributes["service.name"] == "") and resource.attributes["k8s.daemonset.name"] != nil and resource.attributes["k8s.daemonset.name"] != ""`,
`set(resource.attributes["service.name"], resource.attributes["k8s.cronjob.name"]) where (resource.attributes["service.name"] == nil or resource.attributes["service.name"] == "") and resource.attributes["k8s.cronjob.name"] != nil and resource.attributes["k8s.cronjob.name"] != ""`,
`set(resource.attributes["service.name"], resource.attributes["k8s.job.name"]) where (resource.attributes["service.name"] == nil or resource.attributes["service.name"] == "") and resource.attributes["k8s.job.name"] != nil and resource.attributes["k8s.job.name"] != ""`,
`set(resource.attributes["service.name"], resource.attributes["k8s.pod.name"]) where (resource.attributes["service.name"] == nil or resource.attributes["service.name"] == "") and resource.attributes["k8s.pod.name"] != nil and resource.attributes["k8s.pod.name"] != ""`,

// Set service.namespace to the pod namespace if not already set
`set(resource.attributes["service.namespace"], resource.attributes["k8s.namespace.name"]) where (resource.attributes["service.namespace"] == nil or resource.attributes["service.namespace"] == "") and resource.attributes["k8s.namespace.name"] != nil and resource.attributes["k8s.namespace.name"] != ""`,

// Remove the temporary attributes used for service.name detection
`delete_key(resource.attributes, "k8s_monitoring.tmp.instance")`,
`delete_key(resource.attributes, "k8s_monitoring.tmp.name")`,
{{- end }}

{{/*
Delete the service.name resource attribute when it is an OpenTelemetry SDK default (unknown_service*), so the value is
treated as unset. This runs before the service.name detection statements, so the fallback detection can populate a
meaningful name in its place.
*/}}
{{- define "feature.applicationObservability.processor.transform.overrideUnknownServiceNameStatements" }}
// Drop the OpenTelemetry SDK default service.name (unknown_service*) so it is treated as unset
`delete_key(resource.attributes, "service.name") where resource.attributes["service.name"] != nil and IsMatch(resource.attributes["service.name"], "^unknown_service")`,
{{- end }}
{{- define "feature.applicationObservability.processor.transform.alloy" }}
otelcol.processor.transform "{{ .name | default "default" }}" {
  error_mode = {{ .Values.processors.transform.errorMode | quote }}

{{- if .Values.metrics.enabled }}
{{- if or .Values.metrics.transforms.resource .Values.alignServiceNameWithOTelSemConv .Values.overrideUnknownServiceNames }}
  metric_statements {
    context = "resource"
    statements = [
{{- range $transform := .Values.metrics.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- if .Values.overrideUnknownServiceNames }}{{- include "feature.applicationObservability.processor.transform.overrideUnknownServiceNameStatements" . | indent 6 }}{{- end }}
{{- if .Values.alignServiceNameWithOTelSemConv }}{{- include "feature.applicationObservability.processor.transform.serviceDetectionStatements" . | indent 6 }}{{- end }}
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
{{- if .Values.overrideUnknownServiceNames }}{{- include "feature.applicationObservability.processor.transform.overrideUnknownServiceNameStatements" . | indent 6 }}{{- end }}
{{- if .Values.alignServiceNameWithOTelSemConv }}{{- include "feature.applicationObservability.processor.transform.serviceDetectionStatements" . | indent 6 }}{{- end }}
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
{{- if or .Values.traces.transforms.resource .Values.alignServiceNameWithOTelSemConv .Values.overrideUnknownServiceNames }}
  trace_statements {
    context = "resource"
    statements = [
{{- range $transform := .Values.traces.transforms.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- if .Values.overrideUnknownServiceNames }}{{- include "feature.applicationObservability.processor.transform.overrideUnknownServiceNameStatements" . | indent 6 }}{{- end }}
{{- if .Values.alignServiceNameWithOTelSemConv }}{{- include "feature.applicationObservability.processor.transform.serviceDetectionStatements" . | indent 6 }}{{- end }}
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
