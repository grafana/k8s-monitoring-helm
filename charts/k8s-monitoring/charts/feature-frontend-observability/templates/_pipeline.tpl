{{- define "feature.frontendObservability.pipeline" }}
# Format:
# - name: Alloy component name
#   description: Human friendly description of the component
#   component: Component slug (used for including "feature.frontendObservability.%s.alloy")
#   targets:
#     <type>: <list>
#       - name: Name of the target
#         component: Component slug (used for including "feature.frontendObservability.%s.alloy.target")
#     <type>: <string> Raw target string (useful for terminating with argument.<type>_destinations.value)
#     <type>: <null>   No target defined for this type
{{- if .Values.receivers.faro.enabled }}
- name: default
  description: Faro Receiver
  component: receiver.faro
  targets:
{{- if .Values.processors.memoryLimiter.enabled }}
    logs: [{name: default, component: processor.memory_limiter}]
    traces: [{name: default, component: processor.memory_limiter}]
{{- else }}
    logs: [{name: default, component: processor.batch}]
    traces: [{name: default, component: processor.batch}]
{{- end }}
{{- end }}

{{- if .Values.processors.memoryLimiter.enabled }}
- name: default
  description: Memory Limiter
  component: processor.memory_limiter
  targets:
    logs: [{name: default, component: processor.batch}]
    traces: [{name: default, component: processor.batch}]
{{- end }}

- name: default
  description: Batch Processor
  component: processor.batch
  targets:
    logs: argument.logs_destinations.value
    traces: argument.traces_destinations.value

{{- end }}
