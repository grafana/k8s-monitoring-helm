{{/* Validates that the Alloy instance is appropriate for the given Pod Logs settings */}}
{{/* Inputs: Values (Pod Logs values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.podLogs.collector.validate" -}}
{{- if or .Values.volumeGathering.enabled (eq .Values.gatherMethod "volumes") }}
  {{- if not (eq .Collector.controller.type "daemonset") }}
    {{- fail (printf "Pod Logs feature requires Alloy to be a DaemonSet when using the \"volumes\" gather method.\nPlease set:\n%s:\n  controller:\n    type: daemonset" .CollectorName) }}
  {{- end -}}
  {{- if not .Collector.alloy.mounts.varlog }}
    {{- fail (printf "Pod Logs feature requires Alloy to mount /var/log when using the \"volumes\" gather method.\nPlease set:\n%s:\n  alloy:\n    mounts:\n      varlog: true" .CollectorName) }}
  {{- end -}}
{{- end -}}

{{- if or .Values.kubernetesApiGathering.enabled (eq .Values.gatherMethod "kubernetesApi") }}
  {{- if not .Collector.alloy.clustering.enabled }}
    {{- if eq .Collector.controller.type "daemonset" }}
      {{- fail (printf "Pod Logs feature requires Alloy DaemonSet to be in clustering mode when using the \"kubernetesApi\" gather method.\nPlease set:\n%s:\n  alloy:\n    clustering:\n      enabled: true" .CollectorName) }}
    {{- else if gt (.Collector.controller.replicas | int) 1 }}
      {{- fail (printf "Pod Logs feature requires Alloy with multiple replicas to be in clustering mode when using the \"kubernetesApi\" gather method.\nPlease set:\n%s:\n  alloy:\n    clustering:\n      enabled: true" .CollectorName) }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- if .Values.lokiReceiver.enabled }}
  {{- if not .Collector.alloy.clustering.enabled }}
    {{- fail (printf "Pod Logs feature requires Alloy to be in clustering mode when using the \"kubernetesApi\" gather method.\nPlease set:\n%s:\n  alloy:\n    clustering:\n      enabled: true" .CollectorName) }}
  {{- end -}}
{{- end -}}


{{- end -}}
