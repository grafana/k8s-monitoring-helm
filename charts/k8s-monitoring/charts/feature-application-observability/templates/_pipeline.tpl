{{- define "feature.applicationObservability.pipeline" }}
# Format:
# - name: Alloy component name
#   description: Human friendly description of the component
#   component: Component slug (used for including "feature.applicationObservability.%s.alloy")
#   targets:
#     <type>: <list>
#       - name: Name of the target
#         component: Component slug (used for including "feature.applicationObservability.%s.alloy.target")
#     <type>: <string> Raw target string (useful for terminating with argument.<type>_destinations.value)
#     <type>: <null>   No target defined for this type
{{- if or .Values.receivers.otlp.grpc.enabled .Values.receivers.otlp.http.enabled }}
- name: default
  description: OTLP Receiver
  component: receiver.otlp
  targets:
    metrics: [{name: default, component: processor.resourcedetection}]
    logs: [{name: default, component: processor.resourcedetection}]
    traces: [{name: default, component: processor.resourcedetection}]
{{- end }}
{{- if or .Values.receivers.jaeger.grpc.enabled .Values.receivers.jaeger.thriftBinary.enabled .Values.receivers.jaeger.thriftCompact.enabled .Values.receivers.jaeger.thriftHttp.enabled }}
- name: default
  description: Jaeger Receiver
  component: receiver.jaeger
  targets:
    traces: [{name: default, component: processor.resourcedetection}]
{{- end }}
{{- if .Values.receivers.zipkin.enabled }}
- name: default
  description: Zipkin Receiver
  component: receiver.zipkin
  targets:
    traces: [{name: default, component: processor.resourcedetection}]
{{- end }}

- name: default
  description: Resource Detection Processor
  component: processor.resourcedetection
  targets:
    metrics: [{name: default, component: processor.k8sattributes}]
    logs: [{name: default, component: processor.k8sattributes}]
    traces: [{name: default, component: processor.k8sattributes}]

- name: default
  description: K8s Attributes Processor
  component: processor.k8sattributes
  targets:
    metrics: [{name: default, component: processor.transform}]
    logs: [{name: default, component: processor.transform}]
{{- if (index .Values.processors "grafanaCloudMetrics").enabled | default .Values.connectors.grafanaCloudMetrics.enabled }}
    traces: [{name: default, component: processor.transform}, {name: default, component: connector.host_info}]

- name: default
  description: Host Info Connector
  component: connector.host_info
  targets:
    metrics: [{name: default, component: processor.batch}]
{{- else }}
    traces: [{name: default, component: processor.transform}]
{{- end }}

- name: default
  description: Transform Processor
  component: processor.transform
  targets:
{{- if eq (include "feature.applicationObservability.processor.filter.enabled" .) "true" }}
    metrics: [{name: default, component: processor.filter}]
    logs: [{name: default, component: processor.filter}]
    traces: [{name: default, component: processor.filter}]

- name: default
  description: Filter Processor
  component: processor.filter
  targets:
{{- end }}
    metrics: [{name: default, component: processor.batch}]
    logs: [{name: default, component: processor.batch}]
    traces: [{name: default, component: processor.batch}]

- name: default
  description: Batch Processor
  component: processor.batch
  targets:
{{- if .Values.processors.memoryLimiter.enabled }}
    metrics: [{name: default, component: processor.memory_limiter}]
    logs: [{name: default, component: processor.memory_limiter}]
    traces: [{name: default, component: processor.memory_limiter}]

- name: default
  description: Memory Limiter
  component: processor.memory_limiter
  targets:
{{- end }}
{{- if .Values.processors.interval.enabled }}
    metrics: [{name: default, component: processor.interval}]
    logs: [{name: default, component: processor.interval}]
    traces: [{name: default, component: processor.interval}]

- name: default
  description: Interval Processor
  component: processor.interval
  targets:
{{- end }}
    metrics: argument.metrics_destinations.value
    logs: argument.logs_destinations.value
    traces: argument.traces_destinations.value

{{- end }}
