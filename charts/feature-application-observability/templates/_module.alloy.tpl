{{- define "feature.applicationObservability.module" }}
{{- $metricsNext := "" }}
{{- $logsNext := "" }}
{{- $resourceDetection := include "feature.applicationObservability.processor.resourcedetection.alloy.target" dict }}
{{- $k8sAttributes := include "feature.applicationObservability.processor.k8sattributes.alloy.target" dict }}
{{- $grafanaCloudMetrics := include "feature.applicationObservability.connector.host_info.alloy.target" dict }}
{{- $transform := include "feature.applicationObservability.processor.transform.alloy.target" dict }}
{{- $filter := include "feature.applicationObservability.processor.filter.alloy.target" dict }}
{{- $batch := include "feature.applicationObservability.processor.batch.alloy.target" dict }}
{{- $memoryLimiter := include "feature.applicationObservability.processor.memory_limiter.alloy.target" dict }}
declare "application_observability" {
  argument "metrics_destinations" {
    comment = "Must be a list of metrics destinations where collected metrics should be forwarded to"
  }

  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  argument "traces_destinations" {
    comment = "Must be a list of trace destinations where collected trace should be forwarded to"
  }

  // Receivers --> Resource Detection Processor
  {{- $next := printf "[%s]" $resourceDetection }}
  {{- include "feature.applicationObservability.receiver.otlp.alloy" (dict "Values" $.Values "metricsOutput" $next "logsOutput" $next "tracesOutput" $next ) | indent 2 }}
  {{- include "feature.applicationObservability.receiver.zipkin.alloy" (dict "Values" $.Values "tracesOutput" $next ) | indent 2 }}

  // Resource Detection Processor --> K8s Attribute Processor
  {{- $next = printf "[%s]" $k8sAttributes }}
  {{- include "feature.applicationObservability.processor.resourcedetection.alloy" (dict "Values" $.Values "metricsOutput" $next "logsOutput" $next "tracesOutput" $next ) | indent 2 }}

  // K8s Attribute Processor --> Transform Processor
  {{- $tracesNext := list $transform }}
  {{- $next = printf "[%s]" $transform }}
{{- if .Values.processors.grafanaCloudMetrics.enabled }}
  // Resource Detection Processor Traces --> Host Info Connector
  {{- $tracesNext = append $tracesNext $grafanaCloudMetrics }}
{{- end -}}
  {{- $tracesNext = printf "[%s]" ($tracesNext | join ", ")}}
  {{- include "feature.applicationObservability.processor.k8sattributes.alloy" (dict "Values" $.Values "metricsOutput" $next "logsOutput" $next "tracesOutput" $tracesNext ) | indent 2 }}

{{- if .Values.processors.grafanaCloudMetrics.enabled }}
  // Host Info Connector --> Batch Processor
  {{- $next = printf "[%s]" $batch }}
  {{- include "feature.applicationObservability.connector.host_info.alloy" (dict "Values" $.Values "metricsOutput" $next ) | indent 2 }}
{{- end }}

{{ if eq (include "feature.applicationObservability.processor.filter.enabled" .) "true" }}
  // Transform Processor --> Filter Processor
  {{- $next = printf "[%s]" $filter }}
{{- else }}
  // Transform Processor --> Batch Processor
  {{- $next = printf "[%s]" $batch }}
{{- end }}
  {{- include "feature.applicationObservability.processor.transform.alloy" (dict "Values" $.Values "metricsOutput" $next "logsOutput" $next "tracesOutput" $next ) | indent 2 }}
{{ if eq (include "feature.applicationObservability.processor.filter.enabled" .) "true" }}
  // Filter Processor --> Batch Processor
  {{- $next = printf "[%s]" $batch }}
  {{- include "feature.applicationObservability.processor.filter.alloy" (dict "Values" $.Values "metricsOutput" $next "logsOutput" $next "tracesOutput" $next ) | indent 2 }}
{{- end }}

{{- if .Values.processors.memoryLimiter.enabled }}
  // Batch Processor --> Memory Limiter
  {{- $metricsNext = printf "[%s]" $memoryLimiter }}
  {{- $logsNext = printf "[%s]" $memoryLimiter }}
  {{- $tracesNext = printf "[%s]" $memoryLimiter }}
{{- else }}
  // Batch Processor --> Destinations
  {{- $metricsNext = "argument.metrics_destinations.value" }}
  {{- $logsNext = "argument.logs_destinations.value" }}
  {{- $tracesNext = "argument.traces_destinations.value" }}
{{- end }}
  {{- include "feature.applicationObservability.processor.batch.alloy" (dict "Values" $.Values "metricsOutput" $metricsNext "logsOutput" $logsNext "tracesOutput" $tracesNext ) | indent 2 }}

{{- if .Values.processors.memoryLimiter.enabled }}
  // Memory Limiter --> Destinations
  {{- $metricsNext = "argument.metrics_destinations.value" }}
  {{- $logsNext = "argument.logs_destinations.value" }}
  {{- $tracesNext = "argument.traces_destinations.value" }}
  {{- include "feature.applicationObservability.processor.memory_limiter.alloy" (dict "Values" $.Values "metricsOutput" $metricsNext "logsOutput" $logsNext "tracesOutput" $tracesNext ) | indent 2 }}
{{- end }}
}
{{- end }}
